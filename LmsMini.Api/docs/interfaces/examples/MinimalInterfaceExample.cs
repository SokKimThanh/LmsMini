using System;
using System.Threading.Tasks;

namespace LmsMini.Api.Docs.Examples
{
    // public interface: c�c ph��ng th?c m?c �?nh l� public
    public interface IGreeter
    {
        Task GreetAsync(); // implicitly public
    }

    // Tri?n khai ng?m (implicit): ph��ng th?c public, c� th? g?i tr?c ti?p
    public class Greeter : IGreeter
    {
        public Task GreetAsync()
        {
            Console.WriteLine("Xin ch�o t? Greeter (tri?n khai ng?m)!");
            return Task.CompletedTask;
        }
    }

    // Tri?n khai t�?ng minh (explicit): ph��ng th?c ch? truy c?p khi cast v? IGreeter
    public class HiddenGreeter : IGreeter
    {
        Task IGreeter.GreetAsync()
        {
            Console.WriteLine("Xin ch�o t? HiddenGreeter (tri?n khai t�?ng minh)!");
            return Task.CompletedTask;
        }
    }

    // Tr?nh ch?y minh ho? t?i gi?n (kh�ng ph?i ph?n c?a app, ch? �? minh ho?)
    public static class MinimalExampleRunner
    {
        public static async Task Run()
        {
            IGreeter g = new Greeter();
            await g.GreetAsync(); // ho?t �?ng -> "Xin ch�o t? Greeter (tri?n khai ng?m)!"

            var hg = new HiddenGreeter();
            // hg.GreetAsync(); // l?i bi�n d?ch: ph��ng th?c kh�ng truy c?p ��?c tr�n HiddenGreeter
            await ((IGreeter)hg).GreetAsync(); // ho?t �?ng -> "Xin ch�o t? HiddenGreeter (tri?n khai t�?ng minh)!"
        }
    }
}
