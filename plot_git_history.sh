GIT_REPO=$1
PCB_FILE_PREFIX=$2
OUTPUT_FILE=$3

set -e

function usage {
	echo "$0 <git repo> <Kicad PCB file prefix> <MP4 output filename>"
}

if [[ -z "$GIT_REPO" ]]
then
	echo "Please provide git repo"
	usage
	exit
fi

if [[ -z "$PCB_FILE_PREFIX" ]]
then
	echo "Please provide pcb file prefix"
	usage
	exit
fi

if [[ -z "$OUTPUT_FILE" ]]
then
	echo "Please provide movie file name"
	usage
	exit
fi

if [[ ! -e `which convert` ]]
then
	echo "Please install ImageMagick"
	exit
fi

GIT_REPO_DIR=`mktemp -d`
PLOT_DIR=`mktemp -d`

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLOT_SCRIPT="$DIR/plot_board.py"

echo =============================================================
echo Plot directory:    $PLOT_DIR
echo Git repo:          $GIT_REPO
echo Output file:       $OUTPUT_FILE
echo PCB prefix:        $PCB_FILE_PREFIX

echo =============================================================
echo Cloning git repo $GIT_REPO into $GIT_REPO_DIR
git clone $GIT_REPO $GIT_REPO_DIR

pushd $GIT_REPO_DIR
	for commit_timestamp_hash in `git log --pretty=format:%at-%H`
	do
		commit_hash=`echo $commit_timestamp_hash | cut -f2 -d-`
		branch_name="plot-$commit_hash"

		echo =============================================================
		echo Checking out commit: $commit_hash
		git checkout -b "$branch_name" $commit_hash

		if [[ ! -e $PCB_FILE_PREFIX.kicad_pcb ]]
		then
			echo =============================================================
			echo "Skipping - PCB file doesn't exist"
			continue
		fi

		mkdir $PLOT_DIR/$commit_timestamp_hash

		echo =============================================================
		echo Plotting PCB
		python $PLOT_SCRIPT $PCB_FILE_PREFIX.kicad_pcb $PLOT_DIR/$commit_timestamp_hash

		echo =============================================================
		echo Converting PCBs to JPG
		for pdf_name in $PLOT_DIR/$commit_timestamp_hash/*.pdf
		do
			convert -quality 100 $pdf_name $pdf_name.jpg
		done

		echo =============================================================
		echo Cleaning up branch
		git checkout master
		git branch -D "$branch_name"
	done
popd

echo =============================================================
echo Laying out images
for i in $PLOT_DIR/*
do
	convert +append $i/*-Cu{Top,Bottom}.pdf.jpg $i/*-CuTopBottom.pdf.jpg
done

echo =============================================================
echo Converting JPGs to MP4
convert -delay 40 $PLOT_DIR/*/*-CuTopBottom.pdf.jpg $OUTPUT_FILE

rm -rf $PLOT_DIR


