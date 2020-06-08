/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jpacker;

/**
 *
 * @author dminer
 */
public class NamedContraintSizedList<T extends SizedObjectInterface>
		extends NamedList<T>
		implements ContraintSizedObjectInterface {
	protected long capacity = -1;
	protected long fragmentation = 0;
	protected long size = 0;


	public NamedContraintSizedList() {}
	public NamedContraintSizedList(String name) {
		this(name, -1);
	}
	public NamedContraintSizedList(long capacity) {
		this.capacity = capacity;
	}
	public NamedContraintSizedList(String name, long capacity) {
		super(name);
		this.capacity = capacity;
	}

	public long getCapacity() {
		return capacity;
	}

	public long getFragmentation() {
		return fragmentation;
	}

	public void setCapacity(long size) {
		fragmentation = this.capacity = capacity;
	}

	public long getSize() {
		return size;
	}

	public void setSize(long size) {
		throw new UnsupportedOperationException("Not supported.");
	}

	@Override
	public boolean add(T o) {
		boolean result = super.add(o);

		if (result) {
			long itemSize = o.getSize();

			if (itemSize + getSize() > getCapacity()) {
				throw new RuntimeException("size contraint violated");
			}
			
			size += itemSize;
			fragmentation -= itemSize;

		}
		return result;
	}

	@Override
	public void clear() {
		super.clear();
		size = 0;
		fragmentation = capacity;
	}
}