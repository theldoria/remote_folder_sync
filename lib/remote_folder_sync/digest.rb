require 'zlib'
require 'digest/md5'

# Do perfomant and memory conservative digest calculation of two files.
class FileDigest
   def step_blocks(file_a, file_b, block_size)
      until file_a.eof?
         a = file_a.read(block_size)
         b = file_b.read(block_size)
         yield a, b
      end
   end

   def test_string_equality(file_a, file_b, block_size)
      step_blocks(file_a, file_b, block_size) do |a, b|
         return false unless a == b
      end
      return true
   end

   def test_crc32_equality(file_a, file_b, block_size)
      step_blocks(file_a, file_b, block_size) do |a, b|
         return false unless Zlib::crc32(a) == Zlib::crc32(b)
      end
      return true
   end

   def test_md5_equality(file_a, file_b, block_size)
      step_blocks(file_a, file_b, block_size) do |a, b|
         return false unless Digest::MD5.digest(a) == Digest::MD5.digest(b)
      end
      return true
   end

   def test_files(filename_a, filename_b, test_method, other_args)
      GC.start

      raise ArgumentError unless File.exists?(filename_a) and File.exists?(filename_b)
      return false unless File.size(filename_a) == File.size(filename_b)
      file_a = File.new(filename_a, 'r')
      file_b = File.new(filename_b, 'r')

      result = send(test_method, file_a, file_b, *other_args)

      file_a.close
      file_b.close

      return result
   end

end

if $0 == __FILE__
   require 'benchmark'

   FILE1 = "digest.rb"
   FILE2 = "digest.rb"
   REPEATS = 100

   d = FileDigest.new

   if $0 == __FILE__
      Benchmark.bmbm(20) do |x|
         x.report("String 1K") {REPEATS.times{d.test_files(FILE1, FILE2,
                                                   :test_string_equality, 1024)}}
         x.report("String 10K") {REPEATS.times{d.test_files(FILE1, FILE2,
                                                    :test_string_equality, 10240)}}
         x.report("String 100K") {REPEATS.times{d.test_files(FILE1, FILE2,
                                                     :test_string_equality, 102400)}}
         x.report("CRC32 1K") {REPEATS.times{d.test_files(FILE1, FILE2,
                                                  :test_crc32_equality, 1024)}}
         x.report("CRC32 10K") {REPEATS.times{d.test_files(FILE1, FILE2,
                                                   :test_crc32_equality, 10240)}}
         x.report("CRC32 100K") {REPEATS.times{d.test_files(FILE1, FILE2,
                                                    :test_crc32_equality, 102400)}}
         x.report("MD5 1K") {REPEATS.times{d.test_files(FILE1, FILE2,
                                                :test_md5_equality, 1024)}}
         x.report("MD5 10K") {REPEATS.times{d.test_files(FILE1, FILE2,
                                                 :test_md5_equality, 10240)}}
         x.report("MD5 100K") {REPEATS.times{d.test_files(FILE1, FILE2,
                                                  :test_md5_equality, 102400)}}
      end
   end
end

