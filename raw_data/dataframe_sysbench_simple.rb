def parse_sysbench(filename)
  sysbench_file = File.open(filename,'r')


  sysbench_data = {}
  sysbench_count = 0

  sysbench_metrics = %w(tps resp_time)

  sysbench_file.each { |line|
    if line =~ /^\[/
      sysbench_data_raw = line.split(',')
      tps = sysbench_data_raw[1].split(' ')[1].to_f
      resp_time = sysbench_data_raw[4].split(' ')[2].gsub('ms', '').to_f

      sysbench_line = [tps, resp_time]

      sysbench_count += 1

      sysbench_data[sysbench_count] = {}

      sysbench_metric_count = 0
      sysbench_metrics.each { |sysbench_metric|
        sysbench_data[sysbench_count][sysbench_metric] = sysbench_line[sysbench_metric_count]
        sysbench_metric_count += 1
      }
    end
  }

  sysbench_file.close
  return sysbench_data
end

def parse_tdctl(filename, td_devices)
  tdctl_file = File.open(filename,'r')

  td_cols = %w(iops rd_m/s wr_m/s lat_us warn error)

  td_count = 1
  td_data = {}
  td_devices.each { |td_device|
    td_data[td_device] = {}
  }

  if !tdctl_file.nil?
    tdctl_file.each { |line|
      line_data = line.split(' ')
      td_devices.each { |td_device|
        if line =~ /.*#{td_device}$/
          td_data[td_device][td_count] = {}
          td_col_count = 1
          td_cols.each { |td_col|
            td_data[td_device][td_count][td_col] = line_data[td_col_count]
            td_col_count += 1
          }
        end
      }
      if line =~ /^[0-9].*[0-9]$/
        td_device="aggr"
        td_data[td_device][td_count] = {}
        td_col_count = 1
        td_cols.each { |td_col|
          td_data[td_device][td_count][td_col] = line_data[td_col_count]
          td_col_count += 1
        }
        td_count += 1
      end
    }
  end
  tdctl_file.close
  return td_data
end

benchmarks = Dir.glob('sysbench**/sysbench**/')
benchmarks.each do |benchmark|
  benchmark_type,storage = benchmark.chop.split('/')[0].split('_')
  benchmark_type,ro_rw,threads = benchmark.chop.split('/')[1].split('_')

  storage = 'eXFlash DIMM_4' if storage == "4mcs"
  storage = 'eXFlash DIMM_8' if storage == "8mcs"
  storage = 'FusionIO' if storage == 'fio'

  benchmark_meta="#{storage},#{ro_rw},#{threads}"

  sysbench_data = parse_sysbench("#{benchmark}/sysbench.out")
  for current_second in 1..sysbench_data.count
    sysbench_data[current_second].each { |k,v|
      puts "#{current_second},#{benchmark_meta},sysbench_#{k},#{v}"
    }
  end

end
