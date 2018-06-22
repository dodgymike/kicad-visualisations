for commit_timestamp_hash in `git log --pretty=format:%at-%H`
do
	commit_hash=`echo $commit_timestamp_hash | cut -f2 -d-`
	echo $commit_hash
	git checkout -b "try3-$commit_hash" $commit_hash
	mkdir /home/iq/auto-plots/$commit_timestamp_hash
	python ./plot_board.py dc26.kicad_pcb /home/iq/auto-plots/$commit_timestamp_hash
	for pdf_name in /home/iq/auto-plots/$commit_timestamp_hash/*.pdf
	do
		convert -quality 100 $pdf_name $pdf_name.jpg
	done
done

for i in /home/iq/auto-plots/*
do
	convert +append $i/dc26-Cu{Top,Bottom}.pdf.jpg $i/dc26-CuTopBottom.pdf.jpg
done

convert -delay 40 /home/iq/auto-plots/*/dc26-CuTopBottom.pdf.jpg CuTopBottom.mp4

