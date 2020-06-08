/*===================================================================*/
/* C program for distribution from the Combinatorial Object Server.  */
/* Generate permutations by transposing adjacent elements            */
/* via the Steinhaus-Johnson-Trotter algorithm.  This is             */
/* the same version used in the book "Combinatorial Generation."     */
/* Both the permutation (in one-line notation) and the positions     */
/* being transposed (as a 2-cycle) are output.                       */
/* The program can be modified, translated to other languages, etc., */
/* so long as proper acknowledgement is given (author and source).   */
/* Programmer: Frank Ruskey, 1995.                                   */
/* The latest version of this program may be found at the site       */
/* http://sue.uvic.ca/~cos/inf/perm/PermInfo.html                    */
/*===================================================================*/
package jpacker;

import java.util.Iterator;

public class SJT implements Iterable<Integer> {
	public interface SJTCallback {
		public void doAction(SJT obj);
	}

	public Iterator<Integer> iterator() {
		return new IntArrayIterator(p, 1, endPosition + 1);
	}

	public SJT(int elementCount) {
		this(elementCount, null);
	}

	public SJT(int elementCount, SJTCallback cb) {
		if (cb == null) {
			callBack = new SJTCallback() {
				public void doAction(SJT obj) {
					obj.printData(p);
				}
			};
		} else {
			this.callBack = cb;
		}
		this.elementCount = elementCount;
		arraySize = elementCount + 1;
		
		// allocate arrays
		p = new int[arraySize];
		pi = new int[arraySize];
		dir = new int[arraySize];
		
		// initialize arrays into "1234..." sequence
		for (int i = 1; i <= elementCount; ++i) {
			dir[i] = -1;
			p[i] = i;
			pi[i] = i;

		}
		setRange(1, elementCount);
	}

	// (begin, end) *inclusive*
	public void setRange(int begin, int end) {
		startPosition = begin;
		endPosition = end;

		permutateTotalCount = 1.0;
		for(int i = begin; i <= end; ++i) {
			permutateTotalCount *= i - begin + 1;
		}
	}
	
	public void execute() {
		permutate(startPosition);
//		System.out.println("");
//		printData(pi);
//		System.out.println("   pi ");
	}

	public int getElementCount() {
		return elementCount;
	}

	public double getPermutateTotalCount() {
		return permutateTotalCount;
	}

	public int[] getPermutation() {
		return p;
	}

	public int getPermutationCount() {
		return permutationCount;
	}
	
	private void move(int x, int d) {
		int z;
		
		printSwap(pi[x], pi[x] + d);
		z = p[pi[x] + d];
		p[pi[x]] = z;
		p[pi[x] + d] = x;
		pi[z] = pi[x];
		pi[x] = pi[x] + d;
	}

	private void permutate(int n) {
		int i;
		
		if (n > endPosition) {
			doCallBack();
		} else {
			permutate(n + 1);
			for (i = startPosition; i <= n - 1; ++i) {
				move(n, dir[n]);
				permutate(n + 1);
			}
			dir[n] = -dir[n];
		}
	}

	private void doCallBack() {
		++permutationCount;
		callBack.doAction(this);
	}

	private void printData(int p[]) {
		int i;
		
		// uncomment if you want to print the index of each perm
//		System.out.format( "[%8d] ", permutationCount ); 
		
		for (i = 1; i <= elementCount; ++i) {
			System.out.format("%d", p[i]);
		}
	}

	private void printSwap(int x, int y) {
//		System.out.format("    (%d %d)\n", x, y);
	}
	
	public static void main(String[] args) {
		int count = 4;
		
		if (args.length > 0) {
			count = Integer.parseInt(args[0]);
		}
		
		SJT perm = new SJT(count);
//		perm.setRange(2, 4);
		perm.execute();
//		System.out.println("");
//		perm.setRange(1, 2);
//		perm.execute();
//		System.out.println("");
	}

	private int arraySize = 0;
	private SJTCallback callBack = null;

	private int elementCount = 0;
	private int startPosition = 0, endPosition = 0;
	private int permutationCount = 0;
	private double permutateTotalCount = 1.0;

	/* The permutation and its inverse */
	private int p[] = null, pi[] = null;

	/* The directions of each element  */
	private int dir[] = null;
}