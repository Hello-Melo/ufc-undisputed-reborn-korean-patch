using System;
using System.IO;
using System.IO.Compression;

// Melo Reborn 한글패치 설치 도구. 별도 DLL 또는 Python 설치가 필요하지 않습니다.
public static class MeloRebornDelta {
    public static void Expand(string source, string delta, string output, int length) {
        if (length <= 0 || length > 67108864) throw new Exception("패치 결과 크기가 허용 범위를 벗어났습니다.");
        byte[] before = String.IsNullOrEmpty(source) ? new byte[0] : File.ReadAllBytes(source);
        byte[] after = new byte[length];
        using (FileStream f = File.OpenRead(delta))
        using (GZipStream z = new GZipStream(f, CompressionMode.Decompress)) {
            int p = 0;
            while (p < length) {
                int n = z.Read(after, p, length-p);
                if (n == 0) throw new Exception("차이 자료가 중간에서 끝났습니다.");
                p += n;
            }
            if (z.ReadByte() != -1) throw new Exception("차이 자료의 크기가 다릅니다.");
        }
        for (int i=0; i<Math.Min(before.Length,after.Length); i++) after[i] ^= before[i];
        File.WriteAllBytes(output, after);
    }
    public static void Replace(string staged, string target) {
        if (File.Exists(target)) File.Replace(staged,target,null);
        else File.Move(staged,target);
    }
}
