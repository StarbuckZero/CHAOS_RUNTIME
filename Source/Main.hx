package;

import com.chaos.engine.plugin.CoreMediaPlugin;
import com.chaos.engine.plugin.CoreChartSupport;
import com.chaos.engine.plugin.CoreUIFrameworkPlugin;
import com.chaos.engine.plugin.CoreFrameworkPlugin;
import com.chaos.engine.CoreEngine;

class Main extends CoreEngine
{
    public function new()
    {
        super();

        CoreFrameworkPlugin.initialize();
        CoreUIFrameworkPlugin.initialize();
        CoreMediaPlugin.initialize();
        CoreChartSupport.initialize();
    }
}
