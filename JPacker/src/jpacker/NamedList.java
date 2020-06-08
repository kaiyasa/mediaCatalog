/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jpacker;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 *
 * @author dminer
 */
public class NamedList<T> implements Iterable<T> {
	NamedList() {}
	NamedList(String name) {
		this.name = name;
	}

	public List<T> getDataList() {
		return dataList;
	}

	public void setDataList(List<T> dataList) {
		this.dataList = dataList;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int length() {
		return dataList.size();
	}

	public Iterator<T> iterator() {
		return dataList.iterator();
	}

	public boolean isEmpty() {
		return dataList.isEmpty();
	}

	public int indexOf(Object o) {
		return dataList.indexOf(o);
	}

	public T get(int index) {
		return dataList.get(index);
	}

	public void clear() {
		dataList.clear();
	}

	public boolean add(T o) {
		return dataList.add(o);
	}


	protected List<T> dataList = new ArrayList<T>();
	private String name = "unnamed";
}