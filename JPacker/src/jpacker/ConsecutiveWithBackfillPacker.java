/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jpacker;

import java.util.LinkedList;
import java.util.List;
import java.util.Queue;
import java.util.Vector;

/**
 *
 * @author dminer
 */
public class ConsecutiveWithBackfillPacker implements MediaPacker {
	private long mediaCapacity;

	public ConsecutiveWithBackfillPacker(long mediaCapacity) {
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

	private MediaInfo getNextMediaInfo(MediaList mediaList) {
		return mediaList.createMediaInfo();
	}

	public MediaList pack(List<DirInfo> dirList) {
		MediaList mediaList = new MediaList(mediaCapacity);
		Queue<MediaInfo> mediaQueue = new LinkedList<MediaInfo>();

		MediaInfo media = getNextMediaInfo(mediaList);
		for(DirInfo curDir : dirList) {
			if (curDir.getSize() <= media.getFragmentation()) {
				media.add(curDir);
				continue;
			}

			// time to split the dir across the media
			DirInfo newDir = new DirInfo(curDir.getName());
			boolean recheck = false;
			int splitCount = 0;

			for(FileInfo curFile : curDir) {
				isFileTooLarge(curFile, media);

				do {
					recheck = false;
					if ((newDir.getSize() + curFile.getSize()) <= media.getFragmentation()) {
						newDir.add(curFile);
					} else {
						// split dir at this point and start a new media object
						if (newDir.getSize() > 0) {
							media.add(newDir);

							if (++splitCount > 1) {
								mediaQueue.add(media);
							} else {
								mediaList.add(media);
							}
							
							newDir = new DirInfo(curDir.getName());
						}
						media = getNextMediaInfo(mediaList);
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

	private void isFileTooLarge(FileInfo curFile, MediaInfo media) throws RuntimeException {
		if (curFile.getSize() > media.getCapacity()) {
			String msg = String.format("File %s too big (%d KB) for media of %d KB", curFile.getPath(), curFile.getSize(), media.getCapacity());
			throw new RuntimeException(msg);
		}
	}
}