package jpacker;

import java.util.Iterator;
import java.util.NoSuchElementException;

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author dminer
 */
public class IntArrayIterator implements Iterator<Integer> {

	public boolean hasNext() {
		return ((start + position + 1) < count);
	}

	public Integer next() {
		if (!hasNext())
			throw new NoSuchElementException();
		return data[++position + start];
	}

	public void remove() {
		throw new UnsupportedOperationException("access denied");
	}

	public IntArrayIterator(int[] data, int start, int count) {
		this.data = data;
		this.start = start;
		this.count = count;
	}

	final int[] data;
	final int start;
	final int count;

	int position = -1;
}