using System;
using System.Threading.Tasks;

namespace LmsMini.Api.Docs.Examples
{
    // public interface: các phýõng th?c m?c ð?nh là public
    public interface IGreeter
    {
        Task GreetAsync(); // implicitly public
    }

    // Tri?n khai ng?m (implicit): phýõng th?c public, có th? g?i tr?c ti?p
    public class Greeter : IGreeter
    {
        public Task GreetAsync()
        {
            Console.WriteLine("Xin chào t? Greeter (tri?n khai ng?m)!");
            return Task.CompletedTask;
        }
    }

    // Tri?n khai tý?ng minh (explicit): phýõng th?c ch? truy c?p khi cast v? IGreeter
    public class HiddenGreeter : IGreeter
    {
        Task IGreeter.GreetAsync()
        {
            Console.WriteLine("Xin chào t? HiddenGreeter (tri?n khai tý?ng minh)!");
            return Task.CompletedTask;
        }
    }

    // Tr?nh ch?y minh ho? t?i gi?n (không ph?i ph?n c?a app, ch? ð? minh ho?)
    public static class MinimalExampleRunner
    {
        public static async Task Run()
        {
            IGreeter g = new Greeter();
            await g.GreetAsync(); // ho?t ð?ng -> "Xin chào t? Greeter (tri?n khai ng?m)!"

            var hg = new HiddenGreeter();
            // hg.GreetAsync(); // l?i biên d?ch: phýõng th?c không truy c?p ðý?c trên HiddenGreeter
            await ((IGreeter)hg).GreetAsync(); // ho?t ð?ng -> "Xin chào t? HiddenGreeter (tri?n khai tý?ng minh)!"
        }
    }
}
