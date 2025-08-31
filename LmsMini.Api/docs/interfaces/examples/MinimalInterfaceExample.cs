using System;
using System.Threading.Tasks;

namespace LmsMini.Api.Docs.Examples
{
    // public interface: c�c ph��ng th?c m?c �?nh l� public
    public interface IGreeter
    {
        Task GreetAsync(); // implicitly public
    }

    // Implicit implementation: ph��ng th?c public, c� th? g?i tr?c ti?p
    public class Greeter : IGreeter
    {
        public Task GreetAsync()
        {
            Console.WriteLine("Hello from Greeter (implicit)!");
            return Task.CompletedTask;
        }
    }

    // Explicit implementation: ph��ng th?c ch? truy c?p khi cast v? IGreeter
    public class HiddenGreeter : IGreeter
    {
        Task IGreeter.GreetAsync()
        {
            Console.WriteLine("Hello from HiddenGreeter (explicit)!");
            return Task.CompletedTask;
        }
    }

    // Minimal demo runner (not part of app, ch? �? minh ho?)
    public static class MinimalExampleRunner
    {
        public static async Task Run()
        {
            IGreeter g = new Greeter();
            await g.GreetAsync(); // works -> "Hello from Greeter (implicit)!"

            var hg = new HiddenGreeter();
            // hg.GreetAsync(); // compile error: method not accessible on HiddenGreeter
            await ((IGreeter)hg).GreetAsync(); // works -> "Hello from HiddenGreeter (explicit)!"
        }
    }
}
