using System;

namespace LmsMini.Api.docs.lessons.interfaces.examples
{
    // Interface: hợp đồng (không có state)
    public interface ILogger
    {
        void Log(string message);
    }

    // Abstract class: có thể chứa state và implementation chung
    public abstract class BaseProcessor
    {
        protected string Name { get; }
        protected BaseProcessor(string name) => Name = name;

        // Một method có implementation chung
        public virtual void Start() => Console.WriteLine($"{Name} starting...");
        public abstract void Process();
    }

    // Sử dụng cả hai: lớp có thể kế thừa abstract class và implement interface
    public class FileProcessor : BaseProcessor, ILogger
    {
        public FileProcessor() : base("FileProcessor") { }

        public override void Process() => Console.WriteLine($"{Name} processing file.");
        public void Log(string message) => Console.WriteLine($"[FileProcessor LOG] {message}");
    }

    // Ví dụ chạy
    public static class Example
    {
        public static void Run()
        {
            BaseProcessor p = new FileProcessor();
            p.Start();
            p.Process();

            ILogger logger = new FileProcessor();
            logger.Log("Điều này sử dụng interface ILogger.");
        }
    }
}
