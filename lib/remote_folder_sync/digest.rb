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

      raise ArgumentError, "File #{filename_a} does not exist" unless File.exists?(filename_a)
      raise ArgumentError, "File #{filename_b} does not exist" unless File.exists?(filename_b)
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

   FILE1 = '\\\\NAS-1T\\photo\\IMG_0011.JPG'
   FILE2 = '\\\\NAS-1T\\photo\\IMG_0011.JPG'
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


#                           user     system      total        real
#String 1K              1.810000   3.463000   5.273000 (  5.787610)
#String 10K             0.718000   0.842000   1.560000 (  1.560003)
#String 100K            0.265000   0.484000   0.749000 (  1.107602)
#CRC32 1K               2.153000   3.650000   5.803000 (  6.333611)
#CRC32 10K              0.561000   0.780000   1.341000 (  1.825203)
#CRC32 100K             0.421000   0.437000   0.858000 (  1.310403)
#MD5 1K                 3.495000   3.588000   7.083000 (  7.597213)
#MD5 10K                0.983000   0.796000   1.779000 (  2.308804)
#MD5 100K               0.749000   0.468000   1.217000 (  1.684803)

end

