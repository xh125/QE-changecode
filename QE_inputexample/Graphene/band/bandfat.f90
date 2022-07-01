module kinds
	implicit none
	integer,parameter :: dp= kind(1.0d0)
end module 

module constants
	implicit none
	integer,parameter :: maxlen = 86
end module 

module io
	use kinds
	use constants
	implicit none
	integer,public,save :: stdout,stdin
	character(len=maxlen) :: stdout_name="bandfat.out"
  character(len=maxlen) :: stdin_name = "bandfat.in"
	character(len=maxlen) :: msg
	integer :: ierr
	contains
	
  function io_file_unit() !得到一个当前未使用的unit，用于打开文件
  !===========================================                                     
  !! Returns an unused unit number
  !! so we can later open a file on that unit.                                       
  !===========================================
  implicit none

    integer :: io_file_unit,unit_index
    logical :: file_open

    unit_index = 9
    file_open  = .true.
    do while ( file_open )
      unit_index = unit_index + 1
      inquire( unit=unit_index, OPENED = file_open ) !用于检查文件状态，参考P.536
    end do
    
    io_file_unit = unit_index

    return
  
  end function io_file_unit
  
  subroutine open_file(file_name,file_unit)
    implicit none
    
    character(len=*),intent(in) :: file_name
    integer,intent(in)          :: file_unit
    open(unit=file_unit, file=file_name,iostat=ierr,iomsg=msg)
    if(ierr /= 0 ) then
      call io_error('Error: Problem opening "'//trim(adjustl(file_name))//' " file')
      call io_error(msg)
    endif
  end subroutine open_file
  
  subroutine close_file(file_name,file_unit)
    implicit none
    
    integer,intent(in)          :: file_unit
    character(len=*),intent(in) :: file_name
    close(file_unit,iostat=ierr,iomsg=msg)
    if(ierr /= 0 ) then
      call io_error('Error: Problem close "'//trim(adjustl(file_name))//' " file')
      call io_error(msg)
    endif   
  end subroutine close_file	
	
	!========================================
  subroutine io_error ( error_msg )
  !========================================
  !! Abort the code giving an error message 
  !========================================

    implicit none
    character(len=*), intent(in) :: error_msg

    write(stdout,*)  'Exiting.......' 
    write(stdout, '(1x,a)') trim(error_msg)    
    close(stdout)    
    write(*, '(1x,a)') trim(error_msg)
    write(*,'(A)') "Error: examine the output/error file for details" 
    STOP
         
  end subroutine io_error
	
  subroutine findkline(funit,kline,indexi,indexe)
    implicit none
      integer,intent(in):: funit
      character(len=*),intent(in) :: kline
      integer,intent(in)::indexi,indexe
      logical :: lfindkline
      character(len=maxlen) :: ctmp
      
      lfindkline = .FAlSE.
      do while(.NOT. lfindkline)
        read(funit,"(A)") ctmp
        if (ctmp(indexi:indexe)==kline) then
          lfindkline = .TRUE.
          backspace(unit=funit)
        endif
      enddo  
  end subroutine findkline	
	
end module 

module parameters
	use kinds
	use constants
	use io
	implicit none
  character(len=maxlen) :: filband,filband0
	character(len=maxlen) :: filproj
	character(len=maxlen) :: bandfatfile
	integer :: bandsunit,projsunit,bandfatunit,bands0unit
	
  namelist /fatinput/ filband,filproj,bandfatfile
  
  contains
  
  subroutine readinput()
    implicit none
    
    stdin = io_file_unit()
    call open_file(stdin_name,stdin)
    
    filband="bands.dat"
    filproj="fatband"
    bandfatfile="fatband.dat.gnu"

    read(UNIT=stdin,nml=fatinput,iostat=ierr,iomsg=msg)
    if(ierr /= 0) then
      call io_error('Error: Problem reading namelist file fatinput')
      call io_error(msg)
    endif  
    close(stdin)    
    
    write(stdout,"(1X,A13,1X,A)") "filband     =", trim(filband)
    write(stdout,*) "filband need to set as the input of bands.x  "
    write(stdout,"(/,1X,A13,1X,A)") "filproj     =", trim(filproj)
    write(stdout,*) "filproj need to set as the input of projwfc.x "
    write(stdout,"(/,1X,A13,1X,A)") "bandfatfile =", trim(bandfatfile)
    write(stdout,*) "the fatband are write to file: ",trim(bandfatfile)
    
  end subroutine readinput
  
end module parameters	

program main
	use kinds
	use constants
	use parameters
	use io
	implicit none
	
	integer :: nbnd,nks,natomwfc
	integer :: ik,iband,ipol,iwfc
	character(len=maxlen) :: ctmp,cformat
	real(kind=dp),allocatable :: kpoints(:,:),Enk(:,:),proj(:,:,:)
	character(len=13),allocatable :: nameatomwfc(:)
	real(kind=dp),allocatable   :: lkline(:)
	
	stdout = io_file_unit()
	call open_file(stdout_name,stdout)
  call readinput()
	bandfatunit = io_file_unit()
	call open_file(bandfatfile,bandfatunit)
	
	
	bandsunit = io_file_unit()
	call open_file(filband,bandsunit)
	read(bandsunit,"(12X,I4,6X,I6)") nbnd,nks
	allocate(kpoints(3,nks),Enk(nbnd,nks))
	write(ctmp,*) nbnd
	do ik=1,nks
		read(bandsunit,'(10x,3f10.6)') (kpoints(ipol,ik),ipol=1,3)
		read(bandsunit,"(10f9.3)") (Enk(iband,ik),iband=1,nbnd)
	enddo
	
	allocate(lkline(nks))
	lkline = 0.0
	filband0 = trim(filband)//".gnu"
  bands0unit = io_file_unit()
  call open_file(filband0,bands0unit)
  do ik =1,nks
    read(bands0unit,"(f10.4)") lkline(ik)
  enddo
  call close_file(filband0,bands0unit)
  
  
	
	
	!WRITE (iunplot, '(3i8)') natomwfc, nkstot, nbnd
  !WRITE (iunplot, '(2l5)') noncolin, lspinorb
	projsunit = io_file_unit()
  filproj = trim(filproj)//".projwfc_up"
	call open_file(filproj,projsunit)
	call findkline(projsunit,"    F    F",1,10)
	backspace(projsunit)
	read(projsunit,"(3i8)") natomwfc,nks,nbnd
	allocate(proj(natomwfc,nbnd,nks))
	allocate(nameatomwfc(natomwfc))
	read(projsunit,*)

	
	do iwfc=1,natomwfc
		read(projsunit,"(5X,A13)") nameatomwfc(iwfc)
		do ik=1,nks
			do iband=1,nbnd
				read(projsunit,"(16X,F20.10)") proj(iwfc,iband,ik)
			enddo
		enddo
	enddo
	
	
	
	write(ctmp,*) natomwfc
	cformat = "(A10,1X,A10,"//trim(adjustl(ctmp))//"(1X,A13))"
	write(bandfatunit,cformat) "longkpoint","Energy(eV)",(nameatomwfc(iwfc),iwfc=1,natomwfc)
	cformat = "(F10.5,1X,F10.5,"//trim(adjustl(ctmp))//"(1X,F13.5))"
	do iband=1,nbnd
		do ik=1,nks
			write(bandfatunit,cformat) lkline(ik),Enk(iband,ik),(proj(iwfc,iband,ik),iwfc=1,natomwfc) 
		enddo
		write(bandfatunit,*)
	enddo
	
end program