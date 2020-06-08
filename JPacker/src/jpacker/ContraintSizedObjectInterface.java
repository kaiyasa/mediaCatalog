/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jpacker;

/**
 *
 * @author dminer
 */
public interface ContraintSizedObjectInterface extends SizedObjectInterface {
	public long getCapacity();
	public void setCapacity(long size);

	public long getFragmentation();
}
