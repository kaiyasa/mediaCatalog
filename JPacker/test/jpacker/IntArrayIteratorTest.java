/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jpacker;

import java.util.NoSuchElementException;
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
public class IntArrayIteratorTest {

    public IntArrayIteratorTest() {
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
	 * Test of hext method, of class IntArrayIterator.
	 */
	@Test
	public void testNext() {
		IntArrayIterator instance = createIterator();
		boolean[] expResults = new boolean[] { true, true, true, true, true, true, false };
		boolean result = false;
		boolean exceptionResult = false;
		
		// iterate over the underlying array, testing proper
		// results for each iteration against the iterator
		for(int i = 0; i <= testData.length; ++i) {
			result = instance.hasNext();
			assertEquals(expResults[i], result);

			try {
				int value = instance.next();
				assertEquals(testData[i], value);
			}
			catch (NoSuchElementException e) {
				// on last iteration, next() should throw
				assertEquals(testData.length, i);
				exceptionResult = true;
			}
		}
		assertEquals(true, exceptionResult);
	}


	/**
	 * Test of remove method, of class IntArrayIterator.
	 */
	@Test
	public void testRemove() {
		boolean expResult = true;
		boolean result = false;

		IntArrayIterator instance = createIterator();
		try {
			instance.remove();
		}
		catch (UnsupportedOperationException e) {
			result = true;
		}
		assertEquals(expResult, result);
	}

	IntArrayIterator createIterator() {
		return new IntArrayIterator(testData, 0, testData.length);
	}

	final int[] testData = new int[] {12, 23, 34, 45, 56, 67};
}