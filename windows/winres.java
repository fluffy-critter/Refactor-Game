/* @file winres.java
 *
 * Modify a Windows executable with an appropriate icon file and license/version/etc. text
 */

import org.boris.pecoff4j.constant.ResourceType;
import org.boris.pecoff4j.io.PEParser;
import org.boris.pecoff4j.io.ResourceParser;
import org.boris.pecoff4j.PE;
import org.boris.pecoff4j.ResourceDirectory;
import org.boris.pecoff4j.ResourceEntry;
import org.boris.pecoff4j.resources.StringFileInfo;
import org.boris.pecoff4j.resources.StringTable;
import org.boris.pecoff4j.resources.VersionInfo;

class winres {
    public static void main(String args[]) throws Exception {
        PE pe = PEParser.parse(args[0]);
        ResourceDirectory rd = pe.getImageData().getResourceTable();

        ResourceEntry[] entries = rd.findResources(ResourceType.VERSION_INFO);
        System.out.println("Executable has " + entries.length + " version entries");
        for (ResourceEntry e : entries) {
            System.out.println(e.getId() + " : " + e.getName());
        }
    }
}
