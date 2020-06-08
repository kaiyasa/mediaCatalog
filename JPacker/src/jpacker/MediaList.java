/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package jpacker;

/**
 *
 * @author dminer
 */
// basically this is a typedef
class MediaInfo extends NamedContraintSizedList<DirInfo> {
	MediaInfo(String name, long capacity) {
		super(name, capacity);
		fragmentation = capacity;
	}
}

class MediaList extends NamedContraintSizedList<MediaInfo> {
	private int counter = 0;
	private long mediaCapacity = 0;

	public MediaList(long capacity) {
		// very subtle, provision for *one* MediaInfo object
		// and the add() method will increase capacity for the
		// next one
		super(capacity);
		this.mediaCapacity = capacity;
	}

	public MediaInfo createMediaInfo() {
		String name = String.format("%02d", ++counter);
		return new MediaInfo(name, mediaCapacity);
	}

	@Override
	public boolean add(MediaInfo o) {
		boolean result = super.add(o);

		if (result) {
			addMedia();
		}
		return result;
	}

	public long getMediaCapacity() {
		return mediaCapacity;
	}

	public void setMediaCapacity(long mediaCapacity) {
		this.mediaCapacity = mediaCapacity;
	}

	// automagically grow this object's capacity to allow more
	// media to be added
	private void addMedia() {
		capacity += mediaCapacity;
		fragmentation += mediaCapacity;
	}
}