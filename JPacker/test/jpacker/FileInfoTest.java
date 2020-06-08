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
public class FileInfoTest {

    public FileInfoTest() {
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
	 * Test of getSize method, of class FileInfo.
	 */
	@Test
	public void testGetSize() {
		long expResult = 128;
		FileInfo instance = createFileInfo("foo", expResult);
		long result = instance.getSize();
		assertEquals(expResult, result);
	}

	/**
	 * Test of setSize method, of class FileInfo.
	 */
	@Test
	public void testSetSize() {
		long size = 256;
		FileInfo instance = createFileInfo("foo", 128);
		instance.setSize(size);
		long expResult = size;
		long result = instance.getSize();
		assertEquals(expResult, result);
	}

	/**
	 * Test of getPath method, of class FileInfo.
	 */
	@Test
	public void testGetPath() {
		FileInfo instance = createFileInfo("foo", 192);
		String expResult = "foo";
		String result = instance.getPath();
		assertEquals(expResult, result);
	}

	/**
	 * Test of setPath method, of class FileInfo.
	 */
	@Test
	public void testSetPath() {
		String path = "foobar";
		FileInfo instance = createFileInfo("bob", 384);
		instance.setPath(path);
		String expResult = path;
		String result = instance.getPath();
		assertEquals(expResult, result);
	}

	private FileInfo createFileInfo(String path, long size) {
		return new FileInfo(size, path);
	}
}