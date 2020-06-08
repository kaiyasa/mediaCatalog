/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package jpacker;

/**
 *
 * @author dminer
 */
class DirInfo extends NamedList<FileInfo> implements SizedObjectInterface {
	protected long size = 0;

	DirInfo(String name) {
		super(name);
	}

	public long getSize() {
		if (size == 0) {
			for (FileInfo f : getDataList()) {
				this.size += f.getSize();
			}
		}
		return size;
	}

	public void setSize(long Size) {
		throw new UnsupportedOperationException("Not supported.");
	}

	public void clear() {
		size = 0;
		super.clear();
	}

	public boolean add(FileInfo o) {
		boolean result = getDataList().add(o);

		if (result) {
			this.size += o.getSize();
		}
		return result;
	}
}