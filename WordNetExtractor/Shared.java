import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;


public class Shared
{
	public static HashMap<String, float[]> WordMap = new HashMap<String, float[]>();

	public static int words;
	public static int size;
	
	private static final int MAX_SIZE = 50;
	
	public static void loadTxtModel(String path)
	{
		BufferedReader br = null;
		try
		{
            br = new BufferedReader(new FileReader(path));;
			
            String line = br.readLine();
            String[] lineSplited = line.split(" ");
            
			words = Integer.parseInt(lineSplited[0]);
            size = Integer.parseInt(lineSplited[1]);

            float vector = 0;

            String key = null;
            float[] value = null;
            for (int i = 0; i < words; i++) {
            	
            	line = br.readLine();
                lineSplited = line.split(" ");
            	
                key = lineSplited[0];
                value = new float[size];
                for (int j = 0; j < size; j++) {
                    vector = Float.parseFloat(lineSplited[j + 1]);
					value[j] = vector;
				}

				WordMap.put(key, value);
            }

        } catch (FileNotFoundException e)
		{
			e.printStackTrace();
		} catch (IOException e)
		{
			e.printStackTrace();
		}
    }

	public static void loadGoogleModel(String path)
	{
		DataInputStream dis = null;
		BufferedInputStream bis = null;
		double len = 0;
		float vector = 0;
		try
		{
			bis = new BufferedInputStream(new FileInputStream(path));
			dis = new DataInputStream(bis);
			
			words = Integer.parseInt(readString(dis));
			size = Integer.parseInt(readString(dis));

			String key;
			float[] value = null;
			float[] valueN = null;
			for (int i = 0; i < words; i++)
			{
				key = readString(dis);
				value = new float[size];
				valueN = new float[size];
				len = 0;
				for (int j = 0; j < size; j++)
				{
					vector = readFloat(dis);
					len += vector * vector;
					value[j] = (float) vector;
				}
				len = Math.sqrt(len);

				for (int j = 0; j < size; j++)
				{
					valueN[j] = value[j] / (float) len;
				}

				WordMap.put(key, value);
			}
			
			bis.close();
			dis.close();
		} catch (FileNotFoundException e)
		{
			e.printStackTrace();			
		} catch (IOException e)
		{
			e.printStackTrace();
		}
	}
	
	public static void saveGoogleModel(String path)
	{
		DataOutputStream dis = null;
		BufferedOutputStream bis = null;

		try
		{
			bis = new BufferedOutputStream(new FileOutputStream(path));
			dis = new DataOutputStream(bis);
			
			dis.writeBytes(Integer.toString(words));
			dis.writeByte(' ');
			dis.writeBytes(Integer.toString(size));
			dis.writeByte('\n');
			
			Iterator<Entry<String, float[]>> it = WordMap.entrySet().iterator();
		    while (it.hasNext())
		    {
		        Map.Entry<String, float[]> pairs = (Map.Entry<String, float[]>)it.next();
		        String key = pairs.getKey();
		        float[] value = pairs.getValue();
		        
		        dis.writeBytes(key);
		        dis.writeByte(' ');
		        
		        for (int j = 0; j < size; j++)
				{
		        	//dis.writeFloat(value[j]);
		        	dis.writeInt(Integer.reverseBytes(Float.floatToIntBits(value[j])));
				}
		        it.remove(); // avoids a ConcurrentModificationException
		    }
			
			bis.close();
			dis.close();
		} catch (FileNotFoundException e)
		{
			e.printStackTrace();			
		} catch (IOException e)
		{
			e.printStackTrace();
		}
	}
	
	public static void convertGoogleModel(String path, String filename)
	{
		PrintWriter writer;
		DataInputStream dis = null;
		BufferedInputStream bis = null;
		
		float vector = 0;
		try
		{
			bis = new BufferedInputStream(new FileInputStream(path));
			dis = new DataInputStream(bis);
			writer = new PrintWriter(filename, "UTF-8");
			
			words = Integer.parseInt(readString(dis));
			size = Integer.parseInt(readString(dis));

			String key;
			float[] value = null;
			float[] valueUnknown = new float[size];
			for (int i = 0; i < words; i++)
			{
				key = readString(dis);
				key = key.toLowerCase();
				value = new float[size];
				for (int j = 0; j < size; j++)
				{
					vector = readFloat(dis);
					value[j] = (float) vector;
					if (i >= words-100000)
						valueUnknown[j] += ((float) vector / 100000);
				}

				if (WordMap.containsKey(key))
					continue;
				
				writer.print(key + " ");
				writer.print(getVectorAsString(value) + "\n");
					
				WordMap.put(key, value);
			}
			
			WordMap.put("<UNK>", valueUnknown);
			writer.print("<UNK>" + " ");
			writer.print(getVectorAsString(valueUnknown) + "\n");
			
			bis.close();
			dis.close();
			writer.close();
		} catch (FileNotFoundException e)
		{
			e.printStackTrace();			
		} catch (IOException e)
		{
			e.printStackTrace();
		}
		
		System.out.printf("%8d / %8d\n", WordMap.size(), words);
	}
	
	public static void saveTxtModel(String filename)
	{
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
		
		writer.print(Integer.toString(words));
		writer.print(" ");
		writer.print(Integer.toString(size));
		writer.print("\n");
		
		// loop through all words
		Iterator<Entry<String, float[]>> it = WordMap.entrySet().iterator();
	    while (it.hasNext())
	    {
	        Map.Entry<String, float[]> pairs = (Map.Entry<String, float[]>)it.next();
	        String key = pairs.getKey();
	        float[] value = pairs.getValue();
	        
			writer.print(key + " ");
			writer.print(getVectorAsString(value) + "\n");
	    }
		
		writer.close();
	}
	
	public static String getVectorAsString(float[] vector)
	{	
		StringBuilder sb = new StringBuilder();

		for (int b = 0; b < size; b++)
		{
			sb.append(vector[b]);
			sb.append(" ");
		}

		return sb.toString().trim();
	}

	private static float readFloat(InputStream is)
	{
		byte[] bytes = new byte[4];
		try
		{
			is.read(bytes);
		} catch (IOException e)
		{
			e.printStackTrace();
		}
		float f = getFloat(bytes);
		return f;
	}

	private static float getFloat(byte[] b)
	{
		int accum = 0;
		accum = accum | (b[0] & 0xff) << 0;
		accum = accum | (b[1] & 0xff) << 8;
		accum = accum | (b[2] & 0xff) << 16;
		accum = accum | (b[3] & 0xff) << 24;
		return Float.intBitsToFloat(accum);
	}

	private static String readString(DataInputStream dis)
	{
		byte[] bytes = new byte[MAX_SIZE];
		StringBuilder sb = new StringBuilder();
		try
		{
			byte b = dis.readByte();
			int i = -1;
			
			if (b == 10)
				b = dis.readByte();

			while (b != 32 && b != 10)
			{
				i++;
				bytes[i] = b;
				b = dis.readByte();
				if (i == 49)
				{
					sb.append(new String(bytes));
					i = -1;
					bytes = new byte[MAX_SIZE];
				}
			}
			sb.append(new String(bytes, 0, i + 1));
			
		} catch (IOException e)
		{
			e.printStackTrace();
		}
		String s = sb.toString();
		return s;
	}
	
	public static void createSyntacticVec(String path, String pathLemmaMap, String filename)
	{
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
		
		HashMap<String, float[]> leadingLemma = new HashMap<String, float[]>();
		
		DataInputStream dis = null;
		BufferedInputStream bis = null;
		BufferedReader br = null;
		double len = 0;
		float vector = 0;
		try
		{
			bis = new BufferedInputStream(new FileInputStream(path));
			dis = new DataInputStream(bis);
			br = new BufferedReader(new FileReader(pathLemmaMap));

			words = Integer.parseInt(readString(dis));
			size = Integer.parseInt(readString(dis));

			String key;
			float[] value = null;
			for (int i = 0; i < words; i++)
			{
				key = readString(dis);
				value = new float[size];
				len = 0;
				for (int j = 0; j < size; j++)
				{
					vector = readFloat(dis);
					len += vector * vector;
					value[j] = vector;
				}
				len = Math.sqrt(len);
				
				String line = br.readLine();
				String keyLemma = line.split("\t")[1];
				
				if (keyLemma.equals("<unknown>"))
					continue;

				keyLemma = line.split("\t")[0];
				
				if (leadingLemma.containsKey(keyLemma))
				{
					float[] diff = leadingLemma.get(keyLemma);
					for (int j = 0; j < size; j++)
					{
						diff[j] -= value[j];
					}
					writer.print(normalizeLemma(key) + " ");
					writer.print(getVectorAsString(diff) + "\n");
				}
				else
				{
					leadingLemma.put(keyLemma, value);
				}
			}

			writer.close();
			bis.close();
			dis.close();
		} catch (FileNotFoundException e)
		{
			e.printStackTrace();
		} catch (IOException e)
		{
			e.printStackTrace();
		}
	}
	
	public static String normalizeText(String s)
	{
		s = s.replace('’', '\'');
		s = s.replace('′', '\'');
		s = s.replace("''", " ");
		s = s.replace("'", " ' ");
		s = s.replace('“', '"');
		s = s.replace('”', '"');
		s = s.replace("\"", " \" ");
		s = s.replace(".", " . ");
		s = s.replace(",", " , ");
		s = s.replace("(", " ( ");
		s = s.replace(")", " ) ");
		s = s.replace("!", " ! ");
		s = s.replace(';', ' ');
		s = s.replace(':', ' ');
		s = s.replace("-", " - ");
		s = s.replace('=', ' ');
		s = s.replace('*', ' ');
		s = s.replace('|', ' ');
		s = s.replace('«', ' ');
		s = s.replace("  ", " ");
		s = s.replace("  ", " ");

		s = s.trim();

		s = s.toLowerCase();

		return s;
	}

	public static String normalizeLemma(String s)
	{
		s = s.replaceAll("\\(..?\\)", "");

		s = normalizeText(s);

		s = s.replace(" ", "_");

		return s;
	}
}
