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
public class DirInfoTest {

    public DirInfoTest() {
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
	 * Test of getSize method, of class DirInfo.
	 */
	@Test
	public void testGetSize() {
		DirInfo instance = createLoadedDirInfo();
		long expResult = testFileSize;
		long result = instance.getSize();
		assertEquals(expResult, result);
	}

	/**
	 * Test of setSize method, of class DirInfo.
	 */
	@Test
	public void testSetSize() {
		long Size = 0L;
		DirInfo instance = createLoadedDirInfo();
		boolean expResult = true;
		boolean result = false;

		try {
			instance.setSize(Size);
		}
		catch (UnsupportedOperationException e) {
			result = true;
		}
		assertEquals(expResult, result);
	}

	/**
	 * Test of clear method, of class DirInfo.
	 */
	@Test
	public void testClear() {
		DirInfo instance = createLoadedDirInfo();
		
		// assert we aren't empty
		boolean expResult = false;
		boolean result = instance.isEmpty();
		assertEquals(expResult, result);

		instance.clear();
		
		// assert we are empty now
		expResult = true;
		result = instance.isEmpty();
		assertEquals(expResult, result);

	}

	/**
	 * Test of add method, of class DirInfo.
	 */
	@Test
	public void testAdd() {
		String fname = "foobar.txt";
		int size = 129;
		FileInfo fileInfo = new FileInfo(size, fname);
		DirInfo instance = new DirInfo("test");

		// make sure the size calculation works
		{
			long expResult = 0;
			long result = instance.getSize();
			assertEquals(expResult, result);
		}

		// we got a true for adding
		{
			boolean expResult = true;
			boolean result = instance.add(fileInfo);
			assertEquals(expResult, result);
		}

		// the object should be in position 0
		{
			FileInfo expResult = fileInfo;
			FileInfo result = instance.get(0);
			assertEquals(expResult, result);
		}

		// add again for size calculation
		{
			boolean expResult = true;
			boolean result = instance.add(fileInfo);
			assertEquals(expResult, result);
		}

		// make sure the size calculation works
		{
			long expResult = size*2;
			long result = instance.getSize();
			assertEquals(expResult, result);
		}
	}

	static final int testFileSize = 65;

	private DirInfo createLoadedDirInfo() {
		DirInfo result = new DirInfo("test");
		boolean ok = result.add(new FileInfo(testFileSize, "bob.txt"));
		assertEquals(true, ok);
		return result;
	}
}