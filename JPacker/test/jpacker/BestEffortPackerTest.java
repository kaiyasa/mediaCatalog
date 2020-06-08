/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jpacker;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
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
public class BestEffortPackerTest {

    public BestEffortPackerTest() {
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
	 * Test of mapSJTIndecies method, of class BestEffortPacker.
	 */
	@Test
	public void testMapSJTIndecies() {
		SJT.SJTCallback cb = new SJT.SJTCallback() {
			BestEffortPacker instance = new BestEffortPacker();
			List<DirInfo> dirList = new ArrayList<DirInfo>();
			List<DirInfo>[] expDirList = new ArrayList[6];
			boolean flag = init();
			
			boolean init() {
				// build master dir list
				dirList.add(new DirInfo("test 1"));
				dirList.add(new DirInfo("test 2"));
				dirList.add(new DirInfo("test 3"));
		
				int[][] permList = new int[][] {
					{1, 2, 3}, {1, 3, 2},
					{3, 1, 2}, {3, 2, 1},
					{2, 3, 1}, {2, 1, 3}
				};
				
				// build all the permutation dir lists
				for(int i = 0; i < permList.length; ++i) {
					expDirList[i] = new ArrayList<DirInfo>();
					for(int j = 0; j < permList[0].length; ++j) {
						expDirList[i].add(dirList.get(permList[i][j] - 1));
					}
				}
				return true;
			}
			
			public void doAction(SJT obj) {
				int idx = obj.getPermutationCount() - 1;
				List<DirInfo> expResult = expDirList[idx];
				List<DirInfo> result = instance.mapSJTIndecies(obj, dirList);
				assertEquals(expResult.size(), result.size());
				
				Iterator<DirInfo> expResultIter = expResult.iterator();
				Iterator<DirInfo> resultIter = result.iterator();
				for(int i = 0; i < expResult.size(); ++i) {
					DirInfo v1 = expResultIter.next();
					DirInfo v2 = resultIter.next();
					assertEquals(v1, v2);
				}
			}
		};

		SJT permGen = new SJT(3, cb);
		permGen.execute();
	}

	/**
	 * Test of generateMediaListBreakData method, of class BestEffortPacker.
	 */
	@Test
	public void testGenerateMediaListBreakData() {
		MediaList mediaList = new MediaList(100);
		MediaInfo mediaInfo = mediaList.createMediaInfo();
		DirInfo dirInfo = new DirInfo("dir 1");
		dirInfo.add(new FileInfo(99, "dir 1/file1"));
		mediaInfo.add(dirInfo);
		mediaList.add(mediaInfo);

		mediaInfo = mediaList.createMediaInfo();
		(dirInfo = new DirInfo("dir 2")).add(new FileInfo(98, "dir 2/file2"));
		mediaInfo.add(dirInfo);
		mediaList.add(mediaInfo);


		BestEffortPacker instance = new BestEffortPacker();
		String expResult = "99\tdir 1/file1\nbreak 99\n98\tdir 2/file2\n";
		String result = instance.generateMediaListBreakData(mediaList);
		System.out.println(result);
		assertEquals(expResult, result);
	}

	class TestCallback implements SJT.SJTCallback {
		public void doAction(SJT obj) {
			throw new UnsupportedOperationException("Not supported yet.");
		}
	}

	private SJT createSJT(int size) {
		return new SJT(size);
	}
}