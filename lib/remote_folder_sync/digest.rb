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

   FILE1 = '/mnt/samba/nas-1t/photo/MVI_0055.MOV' # '\\\\NAS-1T\\photo\\IMG_0011.JPG'
   FILE2 = '/mnt/samba/nas-1t/photo/MVI_0055.MOV' # '\\\\NAS-1T\\photo\\IMG_0011.JPG'
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
         x.report("cksum") {REPEATS.times{`cksum #{FILE1} #{FILE2}`}}
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


#                           user     system      total        real
#String 1K             14.640000   3.710000  18.350000 ( 19.803780)
#String 10K             5.030000   2.510000   7.540000 (  8.811860)
#String 100K            5.650000   2.880000   8.530000 ( 10.491456)
#CRC32 1K              22.400000   7.250000  29.650000 ( 31.133982)
#CRC32 10K              9.130000   4.330000  13.460000 ( 14.738787)
#CRC32 100K             7.830000   4.320000  12.150000 ( 13.349900)
#MD5 1K                53.150000   5.650000  58.800000 ( 62.313742)
#MD5 10K               15.510000   3.570000  19.080000 ( 20.533174)
#MD5 100K              12.600000   3.400000  16.000000 ( 17.678893)
#cksum                  0.130000   0.210000  12.250000 ( 14.121335)


#Rehearsal --------------------------------------------------------
#String 1K            745.440000 193.610000 939.050000 (961.227293)
#String 10K           244.570000 123.520000 368.090000 (379.425590)
#String 100K          265.450000 135.510000 400.960000 (406.050088)
#CRC32 1K             1161.820000 234.230000 1396.050000 (1415.962924)
#CRC32 10K            429.710000 128.260000 557.970000 (568.506907)
#CRC32 100K           405.860000 139.670000 545.530000 (554.406196)
#MD5 1K               2628.170000 304.150000 2932.320000 (2964.755045)
#MD5 10K              774.590000 136.470000 911.060000 (927.476087)
#MD5 100K             595.760000 146.360000 742.120000 (752.078105)
#cksum                  0.100000   0.340000 580.040000 (593.207229)
#-------------------------------------------- total: 9373.190000sec
#
#                           user     system      total        real
#String 1K            732.550000 189.690000 922.240000 (938.755608)
#String 10K           245.110000 124.120000 369.230000 (377.255419)
#String 100K          263.890000 138.080000 401.970000 (411.096762)
#CRC32 1K             1152.060000 229.720000 1381.780000 (1400.194235)
#CRC32 10K            432.620000 124.470000 557.090000 (565.168935)
#CRC32 100K           408.280000 136.280000 544.560000 (553.190437)
#MD5 1K               2625.500000 288.880000 2914.380000 (2949.428010)
#MD5 10K              773.940000 135.220000 909.160000 (920.700538)
#MD5 100K             592.450000 144.020000 736.470000 (751.733252)
#cksum                  0.090000   0.240000 565.490000 (571.322411)

end

