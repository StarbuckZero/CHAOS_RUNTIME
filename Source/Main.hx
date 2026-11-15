package;

import com.chaos.engine.plugin.CoreMediaPlugin;
import com.chaos.engine.plugin.CoreChartSupport;
import com.chaos.engine.plugin.CoreUIFrameworkPlugin;
import com.chaos.engine.plugin.CoreFrameworkPlugin;
import com.chaos.engine.CoreEngine;

#if (cpp && linux)
@:buildXml("<target id=\"haxe\"><flag value=\"-Wl,-rpath,$ORIGIN\"/></target>")
#end
#if (cpp && mac)
@:buildXml("<target id=\"haxe\"><flag value=\"-Wl,-rpath,@loader_path\"/></target>")
#end
class Main extends CoreEngine
{
    public function new(autoLoadProject:Bool = true)
    {
        super(autoLoadProject);

        CoreFrameworkPlugin.initialize();
        CoreUIFrameworkPlugin.initialize();
        CoreMediaPlugin.initialize();
        CoreChartSupport.initialize();
    }
}
