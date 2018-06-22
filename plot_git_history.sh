GIT_REPO=$1
PCB_FILE_PREFIX=$2

set -e

if [[ -z "$GIT_REPO" ]]
then
	echo "Please provide git repo"
	exit
fi

if [[ -z "$PCB_FILE_PREFIX" ]]
then
	echo "Please provide pcb file prefix"
	exit
fi

if [[ ! -e `which convert` ]]
then
	echo "Please install ImageMagick"
	exit
fi

GIT_REPO_DIR=`mktemp -d`
PLOT_DIR=`mktemp -d`

echo =============================================================
echo Plot directory:    $PLOT_DIR
echo Git repo:          $GIT_REPO
echo PCB prefix:        $PCB_FILE_PREFIX
echo =============================================================

echo =============================================================
echo Cloning git repo $GIT_REPO into $GIT_REPO_DIR
echo =============================================================
git clone $GIT_REPO $GIT_REPO_DIR

pushd $GIT_REPO_DIR
	for commit_timestamp_hash in `git log --pretty=format:%at-%H`
	do
		commit_hash=`echo $commit_timestamp_hash | cut -f2 -d-`
		branch_name="plot-$commit_hash"

		echo =============================================================
		echo Checking out commit: $commit_hash
		echo =============================================================
		git checkout -b "$branch_name" $commit_hash

		mkdir $PLOT_DIR/$commit_timestamp_hash

		echo =============================================================
		echo Plotting PCB
		echo =============================================================
		python ./plot_board.py $PCB_FILE_PREFIX.kicad_pcb $PLOT_DIR/$commit_timestamp_hash

		echo =============================================================
		echo Converting PCBs to JPG
		echo =============================================================
		for pdf_name in $PLOT_DIR/$commit_timestamp_hash/*.pdf
		do
			convert -quality 100 $pdf_name $pdf_name.jpg
		done

		git checkout master
		git branch -D "$branch_name"
	done
popd

echo =============================================================
echo Laying out images
echo =============================================================
for i in $PLOT_DIR/*
do
	convert +append $i/$PCB_FILE_PREFIX-Cu{Top,Bottom}.pdf.jpg $i/$PCB_FILE_PREFIX-CuTopBottom.pdf.jpg
done

echo =============================================================
echo Converting JPGs to MP4
echo =============================================================
convert -delay 40 $PLOT_DIR/*/$PCB_FILE_PREFIX-CuTopBottom.pdf.jpg CuTopBottom.mp4

rm -rf $PLOT_DIR


