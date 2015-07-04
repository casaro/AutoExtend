import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Scanner;

import net.didion.jwnl.JWNL;
import net.didion.jwnl.JWNLException;
import net.didion.jwnl.data.IndexWord;
import net.didion.jwnl.data.IndexWordSet;
import net.didion.jwnl.data.POS;
import net.didion.jwnl.data.Pointer;
import net.didion.jwnl.data.PointerType;
import net.didion.jwnl.data.Synset;
import net.didion.jwnl.data.Word;
import net.didion.jwnl.dictionary.Dictionary;
import net.didion.jwnl.dictionary.MorphologicalProcessor;

@SuppressWarnings("unchecked")
public class WordNetExtractor
{
	private static HashMap<String, float[]> wordMap = new HashMap<String, float[]>();

	private static HashMap<String, Integer> WordIndex = new HashMap<String, Integer>();
	private static HashMap<String, Integer> SynsetIndex = new HashMap<String, Integer>();
	

	private static int words;
	private static int size;

	private static final int MAX_SIZE = 50;

	private static Dictionary dictionary;

	public static void main(String[] args) throws IOException, JWNLException
	{
		// path to JWNL prop xml file
		JWNL.initialize(new FileInputStream("[...]"));
		dictionary = Dictionary.getInstance();
		
		// path to input word embeddings
		String file_name = "[...]";
		
		// path to output folder
		String folder = "[...]";
		
		if (file_name.endsWith(".bin"))
			Shared.loadGoogleModel(file_name);
		else
			Shared.loadTxtModel(file_name);
		
		JWNL.Version ver = JWNL.getVersion();
		System.out.printf("RESOURCE: WN " + ver.toString() + "\n");
		System.out.printf("VECTORS: " + folder + "\n");
		System.out.printf("TARGET: " + folder + "\n");

		extractWordsAndSynsets(folder + "words.txt",
				folder + "synsets.txt",
				folder + "lexemes.txt",
				folder + "glosses.txt");

		extractSynsetRelations(folder + "hypernym.txt", PointerType.HYPERNYM);
		extractSynsetRelations(folder + "similar.txt", PointerType.SIMILAR_TO);
		extractSynsetRelations(folder + "verbGroup.txt", PointerType.VERB_GROUP);
		extractSynsetRelations(folder + "antonym.txt", PointerType.ANTONYM);

		System.out.printf("DONE");
	}	
	
	private static void extractWordsAndSynsets(String filenameWords, String filenameSynsets, String filenameLexemes, String filenameGlosses) throws JWNLException
	{
		// create file
		PrintWriter writerWords, writerSynsets, writerLexemes, writerGlosses;
		try
		{
			writerWords = new PrintWriter(filenameWords, "UTF-8");
			writerSynsets = new PrintWriter(filenameSynsets, "UTF-8");
			writerLexemes = new PrintWriter(filenameLexemes, "UTF-8");
			writerGlosses = new PrintWriter(filenameGlosses, "UTF-8");
		} catch (FileNotFoundException | UnsupportedEncodingException e)
		{
			e.printStackTrace();

			return;
		}

		int wordCounter = 0;
		int synsetCounter = 0;
		int synsetCounterAll = 0;
		int lexemCounter = 0;
		int lexemCounterAll = 0;

		HashSet<String> oov = new HashSet<String>();
		
		for (Object pos : POS.getAllPOS())
		{
			Iterator<Synset> itr = dictionary.getSynsetIterator((POS) pos);
			while (itr.hasNext())
			{
				Synset synset = itr.next();
				String synsetId = getId(synset);
				++synsetCounterAll;
				
				SynsetIndex.put(synsetId, synsetCounterAll);

				// export synset
				writerSynsets.print(synsetId + " ");
				
				float[] naiveSynsetVector = new float[size];
				int wordsInSynset = 0;

				for (Word word : synset.getWords())
				{
					++lexemCounterAll;

					String lemma = word.getLemma();
					lemma = Shared.normalizeLemma(lemma);

					// if not in corpus maybe with pos tag
					if (!wordMap.containsKey(lemma))
					{
						lemma = lemma + "%" + synset.getPOS().getKey();							
						
						// skip words that are not in corpus
						if (!wordMap.containsKey(lemma))
						{
							oov.add(lemma);
							continue;
						}
					}
					
					++wordsInSynset;
					for (int b = 0; b < size; b++)
					{
						naiveSynsetVector[b] += wordMap.get(lemma)[b];
					}

					if (!WordIndex.containsKey(lemma))
					{
						writerWords.print(lemma + " " + Shared.getVectorAsString(wordMap.get(lemma)) + "\n");
						WordIndex.put(lemma, ++wordCounter);
					}

					++lexemCounter;

					String sensekey = synset.getSenseKey(word.getLemma());

					writerSynsets.print(sensekey + ",");
					writerLexemes.print(WordIndex.get(lemma) + " " + synsetCounterAll + "\n");
				}
				writerSynsets.print("\n");
				
				// get gloss vector and normalize length of it
				float[] glossVector = getGlossVector(synset);
				if (wordsInSynset != 0)
				{
					float lenNSV = 0, lenGloss = 0;
					for (int b = 0; b < size; b++)
					{
						naiveSynsetVector[b] /= wordsInSynset;
						lenNSV += naiveSynsetVector[b] * naiveSynsetVector[b];
						lenGloss += glossVector[b] * glossVector[b];
					}
					lenNSV = (float)Math.sqrt(lenNSV);
					lenGloss = (float)Math.sqrt(lenGloss);
					for (int b = 0; b < size; b++)
					{
						glossVector[b] *= (lenNSV / lenGloss);
					}
				}
				else
				{
					float lenGloss = 0;
					for (int b = 0; b < size; b++)
					{
						lenGloss += glossVector[b] * glossVector[b];
					}
					lenGloss = (float)Math.sqrt(lenGloss);
					for (int b = 0; b < size; b++)
					{
						glossVector[b] /= lenGloss;
					}
				}
				
				writerGlosses.print(synsetId + " " + Shared.getVectorAsString(glossVector) + "\n");
				
				if (wordsInSynset != 0)
					++synsetCounter;
				else
					SynsetIndex.put(synsetId, -1);
			}
		}

		writerWords.close();
		writerSynsets.close();
		writerLexemes.close();
		writerGlosses.close();

		System.out.printf("   Words: %8d / %8d\n", wordCounter, wordCounter + oov.size());
		System.out.printf("  Synset: %8d / %8d\n", synsetCounter, synsetCounterAll);
		System.out.printf("  Lexems: %8d / %8d\n", lexemCounter, lexemCounterAll);
	}
	
	private static String getId(Synset synset)
	{
		JWNL.Version ver = JWNL.getVersion();
		
		String id = "wn-" + ver.getNumber() + "-" + String.format("%08d", synset.getOffset()) + "-" + synset.getPOS().getKey();
		
		return id;
	}

	private static float[] getGlossVector(Synset synset)
	{
		String gloss = Shared.normalizeText(synset.getGloss());
		
		float[] vector = new float[size];
		for (String word : gloss.split(" "))
		{
			if (wordMap.containsKey(word))
			{
				for (int b = 0; b < size; b++)
				{
					vector[b] += wordMap.get(word)[b];
				}
			}
		}
		
		return vector;
	}

	private static void extractSynsetRelations(String filename, PointerType pointer) throws JWNLException
	{
		HashMap<String, Integer> affectedPOS = new HashMap<String, Integer>();
		
		// create file
		PrintWriter writer;
		try
		{
			writer = new PrintWriter(filename, "UTF-8");
		} catch (FileNotFoundException | UnsupportedEncodingException e)
		{
			e.printStackTrace();

			return;
		}

		for (Object pos : POS.getAllPOS())
		{
			Iterator<Synset> itr = dictionary.getSynsetIterator((POS) pos);
			while (itr.hasNext())
			{
				Synset synset = itr.next();
				String synsetId = getId(synset);

				Pointer[] pointers = synset.getPointers(pointer);
				for (Pointer p : pointers)
				{
					Synset targetSynset = p.getTargetSynset();
					String targetId = getId(targetSynset);;
					
					String key = targetSynset.getPOS().getLabel();					
					if (affectedPOS.containsKey(key))
					{
						affectedPOS.put(key, affectedPOS.get(key) + 1);
					}
					else
					{
						affectedPOS.put(key, 1);
					}
					
					if (SynsetIndex.get(synsetId) < 0 || SynsetIndex.get(targetId) < 0)
						continue;

					writer.print(SynsetIndex.get(synsetId));
					writer.print(" ");
					writer.print(SynsetIndex.get(targetId));
					writer.print("\n");
				}
			}
		}

		writer.close();

		System.out.printf("Extracted %s: done!\n", pointer.getLabel());
		Iterator<Entry<String, Integer>> it = affectedPOS.entrySet().iterator();
		while (it.hasNext())
		{
			Map.Entry<String, Integer> pairs = it.next();
			String key = pairs.getKey();
			int value = pairs.getValue();

			System.out.printf("  %s: %d\n", key, value);
		}
	}
}
