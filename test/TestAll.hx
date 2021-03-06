import utest.Runner;
import utest.ui.Report;

import thx.schema.*;

class TestAll {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new TestSchema());
    runner.addCase(new TestSchemaDynamicExtensions());
    runner.addCase(new TestSchemaGenExtensions());
    runner.addCase(new TestSchemaSchema());
    runner.addCase(new TestGeneric());
    runner.addCase(new TestCore());
    Report.create(runner);
    runner.run();
  }
}
