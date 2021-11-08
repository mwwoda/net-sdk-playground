using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Net.Sdk.Playground.Test
{
    [TestClass]
    public class FooTest
    {
        private readonly Foo _foo;

        public FooTest()
        {
            _foo = new Foo();
        }

        [TestMethod]
        public void FooShouldReturnBar()
        {
            Assert.AreEqual("Bar", _foo.Bar());
        }
    }
}
