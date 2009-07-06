package urlkit.rules
{

import flexunit.framework.*;

public class RulesTests
{
	public static function suite() : TestSuite
	{
		var testSuite:TestSuite = new TestSuite();		
		
		testSuite.addTestSuite(TestUrlValueRule);
		testSuite.addTestSuite(TestUrlRuleSet);
		testSuite.addTestSuite(TestUrlDelegateRule);
		testSuite.addTestSuite(TestUrlNavigatorRule);
		
		return testSuite;
	}
}

}
