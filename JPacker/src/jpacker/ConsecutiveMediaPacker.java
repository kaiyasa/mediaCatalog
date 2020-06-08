/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jpacker;

import java.util.List;

/**
 *
 * @author dminer
 */
public class ConsecutiveMediaPacker implements MediaPacker {
	private long mediaCapacity;

	public ConsecutiveMediaPacker(long mediaCapacity) {
		this.mediaCapacity = mediaCapacity;
	}

	public boolean isBetter(MediaList first, MediaList second) {
		boolean newBest = false;

		if (first.length() >= second.length()) {
			// total frag - last media's frag
			long bFrag = first.getFragmentation() -
					first.get(first.length() - 1).getFragmentation();
			long mFrag = second.getFragmentation() -
					second.get(second.length() - 1).getFragmentation();
			if (bFrag > mFrag) {
				newBest = true;
			}
		}
		return newBest;
	}

	public MediaList pack(List<DirInfo> dirList) {
//		System.out.println("Packing");
		MediaList mediaList = new MediaList(mediaCapacity);

		MediaInfo media = mediaList.createMediaInfo();
		for(DirInfo curDir : dirList) {
			if (curDir.getSize() <= media.getFragmentation()) {
				media.add(curDir);
//				System.out.println("  CWD = " + curDir.name);
				continue;
			}

//			System.out.println("  Spliting " + curDir.name);
			// time to split the dir across the media
			DirInfo newDir = new DirInfo(curDir.getName());
			boolean recheck = false;

			for(FileInfo curFile : curDir) {
				if (curFile.getSize() > media.getCapacity()) {
					String msg = String.format("File %s too big (%d KB) for media of %d KB", curFile.getPath(),curFile.getSize(), media.getCapacity());
					throw new RuntimeException(msg);
				}

				do {
					recheck = false;
					if ((newDir.getSize() + curFile.getSize()) <= media.getFragmentation()) {
						newDir.add(curFile);
//						System.out.println("      Added file to partial");
					} else {
						// split dir at this point and start a new media object
						if (newDir.getSize() > 0) {
//							System.out.println("    partial dir added to media");
							media.add(newDir);
							newDir = new DirInfo(curDir.getName());
						}

						mediaList.add(media);
						media = mediaList.createMediaInfo();
//						System.out.println("  new media");
						recheck = true;
					}
				} while (recheck);
			} // for FileInfo

			if (newDir.getSize() > 0) {
				media.add(newDir);
			}
		} // for DirInfo

		if (media.getSize() > 0) {
			mediaList.add(media);
		}
		return mediaList;
	}
}