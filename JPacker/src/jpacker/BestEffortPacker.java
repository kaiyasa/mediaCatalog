/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jpacker;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.nio.channels.Channel;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import javax.swing.text.StyleContext.NamedStyle;

/**
 *
 * @author dminer
 */
public class BestEffortPacker {
	private FileInputStream kbInput = null;
	private static final String dlsFileFormat = "dls-%s.lst";

	//private long mediaCapacity = 8347540; // DL DVD
	private long mediaCapacity = 4589850; // SL DVD
	
	private int reservedDirectoryCount = 0;
	private String listFileName;
	private String breakFileName = "2break.lst";

	List<DirInfo> dirList = new ArrayList<DirInfo>();
	MediaList bestMediaList = null;
	List<DirInfo> bestDirList = null;
	MediaPacker mediaPacker = new ConsecutiveMediaPacker(mediaCapacity);
	
	public static void main(String args[]) {
		new BestEffortPacker().run(args);
	}

	public BestEffortPacker() {
		try {
			kbInput = new FileInputStream("/dev/stdin");
		} catch (Exception e) {
			throw new RuntimeException("unable to open /dev/stdin", e);
		}
	}

	void handleUI(int trial) throws ResetPermutation, AcceptPermutation {
		try {
			if ((trial % 1000) == 0) {
				System.out.format("\r  Permutation: %- 12d ", trial);
				String line = readKeyboard();
				if (line != null) {
					line = line.trim();
					if (line.equalsIgnoreCase("a")) {
						throw new AcceptPermutation(false);
					}
					if (line.equalsIgnoreCase("s")) {
						writeBreakData();
						return;
					}
					if (line.equalsIgnoreCase("e")) {
						throw new ResetPermutation(true);
					}
					if (line.equalsIgnoreCase("r")) {
						throw new ResetPermutation(false);
					}
					System.out.println("\n\nyay! got '" + line + "'");
				}
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	boolean isNewBest(MediaList trialMediaList) {
		return mediaPacker.isBetter(bestMediaList, trialMediaList);
	}

	private void usage() {
		System.out.println("usage: <reserved dir count> <dir list file>");
	}

	public void run(String[] args) {
		if (args.length < 2) {
			usage();
			System.exit(1);
		}
		
		reservedDirectoryCount = Integer.parseInt(args[0]);
		listFileName = args[1];

		if (args.length >= 3) {
			breakFileName = args[2];
		}
		
		try {
			dirList = loadSizeFileLists(loadListFile(listFileName));

			performPacking();
		}
		catch (IOException e) {
			e.printStackTrace();
			System.exit(1);
		}
	}

	String readKeyboard() throws IOException {
		String result = null;

		byte[] tmp = new byte[1024];
		if (kbInput.available() > 0) {
			int i = kbInput.read(tmp, 0, 1024);
			if (i > 0) {
				result = new String(tmp, 0, i);
			}
		}
		return result;
	}

	class ResetPermutation extends RuntimeException {
		boolean extend = true;
		public ResetPermutation(boolean extend) {
			this.extend = extend;
		}
	}
	class AcceptPermutation extends RuntimeException {
		boolean restart = true;
		public AcceptPermutation(boolean restart) {
			this.restart = restart;
		}
	}

	List<DirInfo> mapSJTIndecies(SJT permGen, List<DirInfo> aDirList) {
		// build the ordered DirList according to permutation ordering
		List<DirInfo> newDirList = new ArrayList<DirInfo>(aDirList.size());
		for(int dirIndex : permGen) {
			newDirList.add(aDirList.get(dirIndex - 1));
		}
		return newDirList;
	}

	void handleCallback(SJT permGen) {
		int trial = permGen.getPermutationCount();

		List<DirInfo> trialDirList = mapSJTIndecies(permGen, dirList);
		MediaList trialMediaList = convertDirListToMediaList(trialDirList);

		if (isNewBest(trialMediaList)) {
			bestDirList = trialDirList;
			bestMediaList = trialMediaList;
			printMediaListSummary(bestMediaList, trial,
					permGen.getPermutateTotalCount(),
					permGen.getPermutation(),
					permGen.getElementCount());
		}
		handleUI(trial);
	}

	void performPacking() {
		SJT.SJTCallback cbHook = new SJT.SJTCallback() {
			public void doAction(SJT obj) {
				handleCallback(obj);
			}
		};

		List<DirInfo> masterDirList = dirList;
		dirList = new ArrayList<DirInfo>();

		boolean showBest = true;
		int size = masterDirList.size();
		int endPosition = size > 8 ? 8 : size;
		SJT permGen = null;
		boolean stop = false;

		while (!stop) {
			try {
				permGen = new SJT(size, cbHook);
				permGen.setRange(reservedDirectoryCount + 1, endPosition);
				if (endPosition > dirList.size()) {
					while (endPosition > dirList.size()) {
						dirList.add(masterDirList.get(dirList.size()));
					}
					bestDirList = dirList;
					bestMediaList = convertDirListToMediaList(dirList);
					showBest = true;
				}
				if (showBest) {
					System.out.println("\n");
					printMediaListSummary(bestMediaList, 1,
						permGen.getPermutateTotalCount(),
						permGen.getPermutation(),
						permGen.getElementCount());
					showBest = false;

				}
				permGen.execute();
				if (endPosition < size) {
					++endPosition;
					showBest = true;
					System.out.println("\n\nAuto expanding");
				} else {
					stop = true;
				}
				dirList = bestDirList;
			}
			catch (ResetPermutation e) {
				if (e.extend) {
					if (++endPosition > size) {
						endPosition = size;
						System.out.println("\n\ncan't extend any further");
					}
				}

				dirList = bestDirList;
				showBest = true;
			}
			catch (AcceptPermutation e) {
				stop = true;
			}
		}
		writeBreakData();
	}

	void writeBreakData() {
		PrintWriter out = null;
		try {
			out = new PrintWriter(new FileOutputStream(breakFileName));
			out.print(generateMediaListBreakData(bestMediaList));
		}
		catch (FileNotFoundException e) {
			e.printStackTrace();;
		}
		finally {
			if (out != null) {
				out.close();
			}
		}
	}

	void printMediaListSummary(MediaList mi, long trial, double permCount, int[] perm, int permLength) {
		long mFrag = mi.getFragmentation() -
			mi.get(mi.length() - 1).getFragmentation();

		long leftOver = mi.get(mi.length()-1).getSize();
		System.out.format("\n\nNew best at %d/%1.0f: count=%d; leftover=%d, totalfrag=%d\n",
				trial, permCount, mi.length(), leftOver, mFrag);
		System.out.print("    index list:");
		for(int i = 1; i <= permLength; ++i) {
			System.out.format(" %d", perm[i] - 1);
		}
		System.out.println("\n");

		long totalFragmentation = 0;
		for(MediaInfo m : mi) {
			totalFragmentation += m.getFragmentation();
			System.out.format("      %s: %-7d %-7d -> %-10d\n",
				m.getName(), m.getSize(), m.getFragmentation(), totalFragmentation);
//			for(DirInfo dir : m) {
//				System.out.println("  Dir: " + dir.name);
//				for(FileInfo f : dir) {
//					System.out.println("      " + f.getPath());
//				}
//			}
		}
	}

	String generateMediaListBreakData(MediaList mediaList) {
		StringBuilder result = new StringBuilder();
		int last = mediaList.length();
		int counter = 0;

		for(MediaInfo curMedia : mediaList) {
			for(DirInfo curDir : curMedia) {
				for(FileInfo curFile : curDir) {
					result.append(String.format("%d\t%s\n", curFile.getSize(), curFile.getPath()));
				}
			}
			
			// don't output the last break statement
			if (++counter != last) {
				result.append(String.format("break %d\n", curMedia.getSize()));
			}
		}
		return result.toString();
	}

	private List<String> loadListFile(String fileName) throws IOException {
		BufferedReader reader =	new BufferedReader(new FileReader(fileName));
		List<String> result = new ArrayList<String>();

		try {
			System.out.println("Loading master list " + fileName);
			while (reader.ready()) {
				String line = reader.readLine();
				result.add(line);
			}
		} finally {
			reader.close();
		}
		return result;
	}

	private List<DirInfo> loadSizeFileLists(List<String> dirNameList) throws IOException {
		BufferedReader reader;
		List<DirInfo> result = new ArrayList<DirInfo>();

		for(String baseName : dirNameList) {
			String dlsFileName = String.format(dlsFileFormat, baseName);
			int lineNumber = 0;
			reader = new BufferedReader(new FileReader(dlsFileName));
			System.out.println("  Loading " + baseName);
				
			try {
				DirInfo dir = new DirInfo(baseName);
				
				while (reader.ready()) {
					String line = reader.readLine();
					++lineNumber;
					
					String data[] = line.split("\t");
					if (data.length == 2) {
						dir.add(new FileInfo(data[0], data[1]));
//						System.out.println("  Adding " + data[1]);
					} else {
						System.out.println("DLS format error: " + dlsFileName + " at line " + lineNumber + ".");
						System.out.println(" '"+line+"'");
					}
				}
				
				if (dir.length() > 0) {
					result.add(dir);
				}
			}
			finally {
				reader.close();
			}
		}
		return result;
	}

	private MediaList convertDirListToMediaList(List<DirInfo> dirList) {
		return mediaPacker.pack(dirList);
	}
}