#!/bin/bash

# The Sea Ice Group at the Geophysical Institute at the University of Alaska
# Fairbanks publishes data collected from their Barrow Sea Ice Mass Balance
# Site. The project's home page can be found at:
#
#   http://seaice.alaska.edu/gi/observatories/barrow_sealevel
#
# I downloaded their 2011 data (found
# here: http://seaice.alaska.edu/gi/data/barrow_massbalance) removed all
# columns except for the timestamp and thermistor readings and deleted the
# first few rows where they were collecting at 2 minute intervals.
#
# This script converts that data into a movie. It uses gnuplot to convert
# each sample (15 minute period) into a PNG. Then it uses ffmpeg to convert
# the PNG frames into an MPEG.
#
# A demo of the output can be found here:
#
#   http://www.youtube.com/watch?v=1ti2c_mm24U


# Clean.
clean () {
  rm *.dat *.png *.tmp
}

# Generate a data file (.dat) for each sample.
make_data () {
  SRC="air-snow-ice-water.txt"
  n=0

  tail --line=+2 "${SRC}" | {
    while read utc day hour temps; do
      x=70
      OUT=$(printf "%05d.dat" "$n")
      {
        echo ${utc}
        for t in ${temps}; do
          echo "${t} ${x}"
          x=$((x = x - 10))
        done
      } > ${OUT}
      n=$((n = n + 1))
    done
  }
}

plot_template () {
  cat <<EOF
set label "SIZONet mass balance probe" at character 13,6
set label "Barrow, AK, 2011" at character 13,5
set label "http://seaice.alaska.edu/gi/observatories/barrow_sealevel" at character 13,4 font "Sans,6"
set term png size 640,360
set output FILE.".png"
set key off
set xtic auto
set xrange [-35:15]
set yrange [-170:70]
set ytic auto
set title "Temperature Gradient through Air, Snow, Ice, and Water"
set xlabel "Temperature (Celsius)"
set ylabel "Position (cm)"
plot 0 lt rgb "blue", "data.tmp" with linespoints lt rgb "red"
EOF
}


# Generate a plot (.png) for each sample.
make_plot () {
  for f in *.dat; do
    FILE=$(basename ${f} .dat)
    TIME=$(head --lines=1 ${f})
    {
      echo "FILE=\"${FILE}\""
      echo "set label \"Day (UTC): ${TIME}\" at character 13,8"
      plot_template
    } > plot.tmp
    tail --lines=+2 ${f} > data.tmp
    gnuplot plot.tmp
done
}


# Generate movie.
make_movie () {
  ffmpeg -r 24 -i %5d.png  -c:v libx264 -crf 23 -pix_fmt yuv420p movie2.mp4
}

#clean
make_data
make_plot
make_movie
