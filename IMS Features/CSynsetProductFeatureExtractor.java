/**
 * IMS (It Makes Sense) -- NUS WSD System
 * Copyright (c) 2010 National University of Singapore.
 * All Rights Reserved.
 */
package sg.edu.nus.comp.nlp.ims.feature;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;

import sg.edu.nus.comp.nlp.ims.corpus.AItem;
import sg.edu.nus.comp.nlp.ims.corpus.ICorpus;
import sg.edu.nus.comp.nlp.ims.corpus.ISentence;
import sg.edu.nus.comp.nlp.ims.util.CSurroundingWordFilter;

/**
 * Synset Product feature extractor.
 */
public class CSynsetProductFeatureExtractor implements IFeatureExtractor {
	
	// the Synsets and corresponding vectors
	protected ArrayList<String> m_Synsets = new ArrayList<String>();
	protected ArrayList<float[]> m_SynsetVectors = new ArrayList<float[]>();

	// corpus to be extracted
	protected ICorpus m_Corpus = null;

	// index of current instance
	protected int m_Index = -1;

	// current sentence to process
	protected ISentence m_Sentence = null;

	// item index in current sentence
	protected int m_IndexInSentence;

	// item length
	protected int m_InstanceLength;

	// index of Synset feature
	protected int m_FeatureIndex = -1;
	
	// sentence before current sentence
	protected int m_Left;

	// sentence after current sentence
	protected int m_Right;
	
	// surrounding words of current instance
	protected HashSet<String> m_SurroundingWordSet = new HashSet<String>();
	
	// vector of surroundings word of current instance
	protected float[] m_SurroundingWordVector;
	
	// current lemma to process
	protected String m_Lemma;
	protected String m_POS;
	
	// stop words filter
	protected CSurroundingWordFilter m_Filter = CSurroundingWordFilter.getInstance();

	// current feature
	protected IFeature m_CurrentFeature = null;
	
	protected static HashMap<String, float[]> wordVectors = new HashMap<String, float[]>();  
	
	protected static int g_LIDX = AItem.Features.LEMMA.ordinal();
	protected static int g_TIDX = AItem.Features.TOKEN.ordinal();
	protected static int g_PIDX = AItem.Features.POS.ordinal();
	
	protected static int DIM_SIZE;


	/**
	 * constructor
	 */
	public CSynsetProductFeatureExtractor() {
		
		createWordVectorSet();
		
		this.m_Left = Integer.MAX_VALUE;
		this.m_Right = Integer.MAX_VALUE;
	}

	/*
	 * (non-Javadoc)
	 * @see sg.edu.nus.comp.nlp.ims.feature.IFeatureExtractor#getCurrentInstanceID()
	 */
	@Override
	public String getCurrentInstanceID() {
		if (this.validIndex(this.m_Index)) {
			return this.m_Corpus.getValue(this.m_Index, "id");
		}
		return null;
	}

	/*
	 * (non-Javadoc)
	 * @see sg.edu.nus.comp.nlp.ims.feature.IFeatureExtractor#hasNext()
	 */
	@Override
	public boolean hasNext() {
		if (this.m_CurrentFeature != null) {
			return true;
		}
		if (this.validIndex(this.m_Index)) {
			this.m_CurrentFeature = this.getNext();
			if (this.m_CurrentFeature != null) {
				return true;
			}
		}
		return false;
	}

	/**
	 * get the next feature of current instance
	 *
	 * @return feature
	 */
	protected IFeature getNext() {
		IFeature feature = null;
		if (this.m_FeatureIndex >= 0 && this.m_FeatureIndex < this.m_Synsets.size() * DIM_SIZE) {
			feature = new CDoubleFeature();
			int index = this.m_FeatureIndex / DIM_SIZE;
			int dimension = this.m_FeatureIndex % DIM_SIZE; 
			feature.setKey(dimension + "_" + this.m_Synsets.get(index));
			feature.setValue(this.getSynsetFeature(index, dimension));
			this.m_FeatureIndex++;
		}
		return feature;
	}

	/**
	 * get the part-of-speech of item p_Index + m_IndexInSentence
	 *
	 * @param p_Index
	 *            index
	 * @return feature value
	 */
	protected String getSynsetFeature(int index, int dimension) {
		
		float result = this.m_SurroundingWordVector[dimension] * this.m_SynsetVectors.get(index)[dimension];
		return Float.toString(result);
	}
	
	private void createWordVectorSet()
	{
		if (wordVectors.size() > 0)
			return;
		
		// path to word and synset vectors
		String path = sg.edu.nus.comp.nlp.ims.implement.CTester.svFile;
		
		System.err.println("Reading word and synsets vector from:");
		System.err.println(path);
		
		BufferedReader br = null;
		try
		{
            br = new BufferedReader(new FileReader(path));;
            
            String key = null;
            
            String line = br.readLine();
            String[] lineSplited = line.split(" ");
            
            DIM_SIZE = Integer.parseInt(lineSplited[1]);
            
            while ((line = br.readLine()) != null) {
            	
                lineSplited = line.split(" ");
            	
                key = lineSplited[0];
                
                float vector[] = new float[DIM_SIZE];
                
                for (int j = 0; j < DIM_SIZE; j++) {
                	vector[j] += Float.parseFloat(lineSplited[j + 1]);
				}
                
                wordVectors.put(key, vector);
            }

        } catch (IOException e)
        {
        	e.printStackTrace();
        }
		
		System.err.println("Done!");
	}

	/**
	 * check the validity of index
	 *
	 * @param p_Index
	 *            index
	 * @return valid or not
	 */
	protected boolean validIndex(int p_Index) {
		if (this.m_Corpus != null && this.m_Corpus.size() > p_Index
				&& p_Index >= 0) {
			return true;
		}
		return false;
	}

	/*
	 * (non-Javadoc)
	 * @see sg.edu.nus.comp.nlp.ims.feature.IFeatureExtractor#next()
	 */
	@Override
	public IFeature next() {
		IFeature feature = null;
		if (this.hasNext()) {
			feature = this.m_CurrentFeature;
			this.m_CurrentFeature = null;
		}
		return feature;
	}

	/*
	 * (non-Javadoc)
	 * @see sg.edu.nus.comp.nlp.ims.feature.IFeatureExtractor#restart()
	 */
	@Override
	public boolean restart() {
		this.m_FeatureIndex = 0;
		this.m_CurrentFeature = null;
		return this.validIndex(this.m_Index);
	}

	/*
	 * (non-Javadoc)
	 * @see sg.edu.nus.comp.nlp.ims.feature.IFeatureExtractor#setCorpus(sg.edu.nus.comp.nlp.ims.corpus.ICorpus)
	 */
	@Override
	public boolean setCorpus(ICorpus p_Corpus) {
		if (p_Corpus == null) {
			return false;
		}
		this.m_Corpus = p_Corpus;
		this.m_Index = 0;
		this.restart();
		this.m_Index = -1;
		this.m_IndexInSentence = -1;
		this.m_InstanceLength = -1;
		return true;
	}
	
	/**
	 * check whether word is in stop word list or contains no alphabet
	 *
	 * @param p_Word
	 *            word
	 * @return true if it should be filtered, else false
	 */
	public boolean filter(String p_Word) {
		return this.m_Filter.filter(p_Word);
	}

	/*
	 * (non-Javadoc)
	 * @see sg.edu.nus.comp.nlp.ims.feature.IFeatureExtractor#setCurrentInstance(int)
	 */
	@Override
	public boolean setCurrentInstance(int p_Index) {
		if (this.validIndex(p_Index)) {
			this.m_Index = p_Index;
			this.m_IndexInSentence = this.m_Corpus.getIndexInSentence(p_Index);
			this.m_InstanceLength = this.m_Corpus.getLength(p_Index);
			int currentSent = this.m_Corpus.getSentenceID(p_Index);
			this.m_Sentence = this.m_Corpus.getSentence(this.m_Corpus
					.getSentenceID(p_Index));
			this.m_Synsets.clear();
			this.m_SynsetVectors.clear();
			this.m_SurroundingWordSet.clear();
			this.m_SurroundingWordVector = new float[DIM_SIZE];
			
			this.m_Lemma = this.m_Sentence.getItem(this.m_IndexInSentence).get(g_LIDX);
			this.m_POS = this.m_Sentence.getItem(this.m_IndexInSentence).get(g_PIDX);
			String posID = "%3";
			
			if (this.m_POS.contains("NN"))
				posID = "%1";
			else if (this.m_POS.contains("VB"))
				posID = "%2";
			else if (this.m_POS.contains("JJ"))
				posID = "%3";
			else if (this.m_POS.contains("RB"))
				posID = "%4";
			else
				posID = "%";
			// add possible synsets
			for (String key : wordVectors.keySet())
			{
		        if (key.startsWith(this.m_Lemma + posID) || key.contains("," + this.m_Lemma + posID) ||
		        	key.startsWith(this.m_Lemma + ",") || key.contains("," + this.m_Lemma + ",") ||
		        	key.equals(this.m_Lemma))
				{
					this.m_Synsets.add(key);
					this.m_SynsetVectors.add(wordVectors.get(key));
				}
			}

			String keyWord = null;
			int lower = this.m_Corpus.getLowerBoundary(currentSent);
			int upper = this.m_Corpus.getUpperBoundary(currentSent);
			for (int sentIdx = lower; sentIdx < upper; sentIdx++) {
				if (currentSent - sentIdx > this.m_Left
						|| sentIdx - currentSent > this.m_Right) {
					continue;
				}
				ISentence sentence = this.m_Corpus.getSentence(sentIdx);
				if (sentence != null) {
					for (int i = 0; i < sentence.size(); i++) {
						keyWord = sentence.getItem(i).get(g_TIDX);
						if (this.filter(keyWord)) {
							continue;
						}
						keyWord = sentence.getItem(i).get(g_LIDX);
						if ((sentIdx != currentSent || i < this.m_IndexInSentence || i >= this.m_IndexInSentence + this.m_InstanceLength)
								&& !this.m_SurroundingWordSet.contains(keyWord))
						{
							this.m_SurroundingWordSet.add(keyWord);
							if (wordVectors.containsKey(keyWord))
							{
								float[] vector = wordVectors.get(keyWord);
								for (int j = 0; j < vector.length; j++) {
				                	this.m_SurroundingWordVector[j] += vector[j];
								}
							}
						}
					}
				}
			}
			this.restart();
			return true;
		}
		return false;
	}

}
