using System;
using System.Threading.Tasks;

namespace LmsMini.Api.docs.lessons.interfaces.examples
{
    // public interface: các phương thức mặc định là public
    public interface IGreeter
    {
        Task GreetAsync(); // implicitly public
    }

    // Triển khai ngầm (implicit): phương thức public, có thể gọi trực tiếp
    public class Greeter : IGreeter
    {
        public Task GreetAsync()
        {
            Console.WriteLine("Xin chào từ Greeter (triển khai ngầm)!");
            return Task.CompletedTask;
        }
    }

    // Triển khai tường minh (explicit): phương thức chỉ truy cập khi cast về IGreeter
    public class HiddenGreeter : IGreeter
    {
        Task IGreeter.GreetAsync()
        {
            Console.WriteLine("Xin chào từ HiddenGreeter (triển khai tường minh)!");
            return Task.CompletedTask;
        }
    }

    // Trình chạy minh họa tối giản (không phải phần của app, chỉ để minh họa)
    public static class MinimalExampleRunner
    {
        public static async Task Run()
        {
            IGreeter g = new Greeter();
            await g.GreetAsync(); // hoạt động -> "Xin chào từ Greeter (triển khai ngầm)!"

            var hg = new HiddenGreeter();
            // hg.GreetAsync(); // lỗi biên dịch: phương thức không truy cập được trên HiddenGreeter
            await ((IGreeter)hg).GreetAsync(); // hoạt động -> "Xin chào từ HiddenGreeter (triển khai tường minh)!"
        }
    }
}
