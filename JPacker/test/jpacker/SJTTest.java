/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jpacker;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;

/**
 *
 * @author dminer
 */
public class SJTTest {
	static final int factCount = 10;
	double factD[] = new double[factCount+1];
	int factI[] = new int[factCount+1];

    public SJTTest() {
		// factoral (aka  N!)
		factD[0] = 1.0;
		factI[0] = 1;
		for(int i = 1; i <= factCount; ++i) {
			factD[i] = i * factD[i-1];
			factI[i] = i * factI[i-1];
		}
    }

	@BeforeClass
	public static void setUpClass() throws Exception {
	}

	@AfterClass
	public static void tearDownClass() throws Exception {
	}

    @Before
    public void setUp() {
    }

    @After
    public void tearDown() {
    }

	/**
	 * Test of setRange method, of class SJT.
	 */
	@Test
	public void testSetRange() {
		int begin = 2;
		int end = 4;
		int size = 6;
		SJT instance = createSJTNoCallback(size);
		instance.setRange(begin, end);
		instance.execute();
		int[] results = instance.getPermutation();
		for(int i = 1; i <= size; ++i) {
			if (!(begin <= i && i <= end))
				assertEquals(i, results[i]);
		}
	}

	class TestCallback implements SJT.SJTCallback {
		TestCallback() {}
		TestCallback(int [][]permList) { this.permList = permList; }

		public void doAction(SJT obj) {
			if (permList != null) {
				assertArrayEquals(permList[callCount], obj.getPermutation());
			}
			++callCount;
		}
		int callCount = 0;
		int [][] permList = null;
	}
	/**
	 * Test of execute method, of class SJT.
	 */
	@Test
	public void testExecute() {
		int size = 3;
		TestCallback cb = new TestCallback();
		SJT instance = new SJT(size, cb);
		instance.execute();
		int expResult = factI[size];
		int result = cb.callCount;

		assertEquals(expResult, result);
	}

	/**
	 * Test of getElementCount method, of class SJT.
	 */
	@Test
	public void testGetElementCount() {
		int size = 6;
		SJT instance = createSJTNoCallback(size);
		int expResult = size;
		int result = instance.getElementCount();
		assertEquals(expResult, result);
	}

	/**
	 * Test of getPermutateTotalCount method, of class SJT.
	 */
	@Test
	public void testGetPermutateTotalCount() {
		int size = 6;

		
		SJT instance = createSJTNoCallback(size);

		// test with no sub range
		double expResult = factD[size];
		double result = instance.getPermutateTotalCount();
		assertEquals(expResult, result, 0.0);

		// now with a sub range
		instance.setRange(1, size-2);
		expResult = factD[size-2];
		result = instance.getPermutateTotalCount();
		assertEquals(expResult, result, 0.0);
	}

	/**
	 * Test of getPermutation method, of class SJT.
	 */
	@Test
	public void testGetPermutation() {
		int size = 6;
		SJT instance = createSJTNoCallback(size);
		int[] expResults = new int[] { 0, 1, 2, 3, 4, 5, 6 };
		int[] results = instance.getPermutation();
		assertNotNull(results);
		assertArrayEquals(expResults, results);

		// test permutation sequence (full range)
		int[][] permList = new int[][] {
			{0, 1, 2, 3},
			{0, 1, 3, 2},
			{0, 3, 1, 2},
			{0, 3, 2, 1},
			{0, 2, 3, 1},
			{0, 2, 1, 3}
		};
		TestCallback cb = new TestCallback(permList);
		size = permList[0].length - 1;
		instance = new SJT(size, cb);
		instance.execute();
		double expResult = factI[size];
		double result = cb.callCount;
		assertEquals(expResult, result, 0.0);

		// now, let's do a subrange in the middle
		permList = new int[][] {
			{0, 1, 2, 3, 4, 5},
			{0, 1, 2, 4, 3, 5},
			{0, 1, 4, 2, 3, 5},
			{0, 1, 4, 3, 2, 5},
			{0, 1, 3, 4, 2, 5},
			{0, 1, 3, 2, 4, 5}
		};

		cb = new TestCallback(permList);
		size = permList[0].length - 1;
		instance = new SJT(size, cb);
		instance.setRange(2, 4);
		instance.execute();
		expResult = factI[size - 2]; // 1 and 5 positions didn't move
		result = cb.callCount;
		assertEquals(expResult, result, 0.0);
	}

	/**
	 * Test of getPermutationCount method, of class SJT.
	 */
	@Test
	public void testGetPermutationCount() {
		int size = 6;
		SJT instance = createSJTNoCallback(size);
		int expResult = 0;
		int result = instance.getPermutationCount();
		assertEquals(expResult, result);

		instance.execute();
		expResult = factI[size];
		result = instance.getPermutationCount();
		assertEquals(expResult, result);
	}

	@Test
	public void testIterator() {
		int[] expResults = new int[] { 1, 2, 3 };
		SJT instance = createSJTNoCallback(3);
		int i = -1;
		for(int value : instance) {
			assertEquals(expResults[++i], value);
		}

	}

	private SJT createSJTNoCallback(int size) {
		return new SJT(size, new SJT.SJTCallback() {
			public void doAction(SJT obj) {
				// big no-op
			}
		});
	}
}