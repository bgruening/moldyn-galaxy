# so the idea here is to create a script that runs through 
# the whole of a simple simulation for the user. This will
# then be wrapped for Galaxy.

# The commands and .mdp files are (for now) based on Justin
# Lemkul's GROMACS tutorial at 
# http://www.bevanlab.biochem.vt.edu/Pages/Personal/justin/gmx-tutorials/lysozyme/

#################
### VARIABLES ###
#################

pdb_input='1AKI.pdb'
# $pdb_output=1AKI_processed.gro
topol='topol.top'
posres='posre.itp'
h2o='spce'
ff='oplsaa'
ignore_h='no'
box_d='1.0'
box_type='cubic'

# .mdp files
ions_mdp='ions'
minim_mdp='minim'
nvt_mdp='nvt'
npt_mdp='npt'
md_mdp='md'

# custom variables in .mdp files
md_steps='5000'
# nvt_steps =, etc ...
step_length='0.002' # in ps; i.e. 2 fs



######################
### EDIT MDP FILES ###
######################

# sed 's/STEPS/500/' < ${ions_mdp}.mdp > ${ions_mdp}_new.mdp

sed 's/STEPS/${md_steps}/' < ${md_mdp}.mdp > ${md_mdp}_new.mdp

for mdp in $ions_mdp $minim_mdp $nvt_mdp $npt_mdp $md_mdp; do 
    sed 's/STEP_LENGTH/${step_length}/' < ${mdp}.mdp > ${mdp}_new.mdp
done

##################
##### SCRIPT #####
##################

# generate topology
gmx pdb2gmx -f $pdb_input -o processed.gro -p $topol -i $posres -water $h2o -ff $ff -${ignore_h}ignh

# generate box
gmx editconf -f processed.gro -o newbox.gro -c -d $box_d -bt $box_type

# solvate box
gmx solvate -cp newbox.gro -cs spc216.gro -o solv.gro -p $topol

# neutralise charge in box
gmx grompp -f ${ions_mdp}_new.mdp -c solv.gro -p $topol -o ions.tpr -maxwarn 1
echo 'SOL' | gmx genion -s ions.tpr -o solv_ions.gro -p $topol -pname NA -nname CL -neutral

# energy minimisation
gmx grompp -f ${minim_mdp}_new.mdp -c solv_ions.gro -p $topol -o em.tpr
gmx mdrun -v -deffnm em

# equilibration - constant volume
gmx grompp -f ${nvt_mdp}_new.mdp -c em.gro -r em.gro -p $topol -o nvt.tpr
gmx mdrun -v -deffnm nvt

# equilibration - constant pressure
gmx grompp -f ${npt_mdp}_new.mdp -c nvt.gro -r em.gro -t nvt.cpt -p $topol -o npt.tpr
gmx mdrun -v -deffnm npt

# run simulation
gmx grompp -f ${md_mdp}_new.mdp -c npt.gro -t npt.cpt -p $topol -o md_0_1.tpr
gmx mdrun -v -deffnm md_0_1