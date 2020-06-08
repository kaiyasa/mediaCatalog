/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jpacker;

import java.util.List;

/**
 *
 * @author dminer
 */
interface MediaPacker {
	MediaList pack(List<DirInfo> dirList);
	// like saying: first < second
	boolean isBetter(MediaList first, MediaList second);
}