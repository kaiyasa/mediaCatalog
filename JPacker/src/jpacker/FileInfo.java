/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package jpacker;

/**
 *
 * @author dminer
 */
class FileInfo implements SizedObjectInterface {
	private long size;
	private String path;

	public FileInfo(long size, String path) {
		this.size = size;
		this.path = path;
	}

	public FileInfo(String size, String path) {
		this.size = Long.parseLong(size);
		this.path = path;
	}

	/**
	 * @return the size
	 */
	public long getSize() {
		return size;
	}

	/**
	 * @param size the size to set
	 */
	public void setSize(long size) {
		this.size = size;
	}

	/**
	 * @return the path
	 */
	public String getPath() {
		return path;
	}

	/**
	 * @param path the path to set
	 */
	public void setPath(String path) {
		this.path = path;
	}
}