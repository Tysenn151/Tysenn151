/****************************************************************
Purpose:  This rule is used to mass copy OBGM regular positions. Used by OBGM on the mass position card,
Created by: InnoFin Solutions
****************************************************************/

SET EMPTYMEMBERSETS ON;
SET AGGMISSG ON;
SET UPDATECALC OFF;

VAR NumPositions = 0;

FIX({Var_CopyPositionSource})	
    "Budget Rate"(
        IF(@ISDESC("Total Existing Positions"))
            @RETURN(@HSPMESSAGE("You selected an existing position. Only new positions can be copied."),Error); 
        ENDIF

        IF({Var_NumofNewPositions} > 30)
            @RETURN(@HSPMESSAGE("The max number of positions that can be copied in the mass copy rules is 30."),Error); 
        ENDIF
    
    )
ENDFIX

FIX(@RELATIVE("Total New Positions",0),"Budget")
	
    SET CREATENONMISSINGBLK ON;
    
    FIX("BegBalance",&BudgetYear,"No_BL","Working","No_PE","No_JC","No_Department","No_Request")

		"FTE"(
        
			IF("FTE" == #Missing) 
            	
            	IF({Var_NumofNewPositions} > NumPositions)
					
					"FTE" = {Var_CopyPositionSource}->{Var_Department}->{Var_Requests}->{Version}->{Var_JobCode}->"FTE";
					{Var_Department}->{Var_Requests}->{Version}->{Var_JobCode}->"FTE" = "FTE"->{Var_CopyPositionSource};
					
                    {Var_Department}->{Var_Requests}->{Version}->{Var_JobCode}->"PositionFlag" = 1;
					NumPositions = NumPositions + 1;
				
				ENDIF
                
			ENDIF
            
   		)
        
	ENDFIX
    
	SET CREATENONMISSINGBLK OFF;
	
	FIX({Var_Department},{Var_Requests},{Version},{Var_JobCode})
    
		FIX(&BudgetYear,"No_PE","No_BL")
        
			"BegBalance"(
            
				IF("PositionFlag" == 1)
                
					"BegBalance" = "BegBalance"->{Var_CopyPositionSource};
					
					"Allocation 1"->"BegBalance" = "Allocation 1"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 2"->"BegBalance" = "Allocation 2"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 3"->"BegBalance" = "Allocation 3"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 4"->"BegBalance" = "Allocation 4"->"BegBalance"->{Var_CopyPositionSource};
					"Allocation 5"->"BegBalance" = "Allocation 5"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 6"->"BegBalance" = "Allocation 6"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 7"->"BegBalance" = "Allocation 7"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 8"->"BegBalance" = "Allocation 8"->"BegBalance"->{Var_CopyPositionSource};
					"Allocation 9"->"BegBalance" = "Allocation 9"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 10"->"BegBalance" = "Allocation 10"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 11"->"BegBalance" = "Allocation 11"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 12"->"BegBalance" = "Allocation 12"->"BegBalance"->{Var_CopyPositionSource};
					"Allocation 13"->"BegBalance" = "Allocation 13"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 14"->"BegBalance" = "Allocation 14"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 15"->"BegBalance" = "Allocation 15"->"BegBalance"->{Var_CopyPositionSource};
                   	"Allocation 16"->"BegBalance" = "Allocation 16"->"BegBalance"->{Var_CopyPositionSource};                    
                   	
  
                   	
					"BegBalance"->"PositionFlag" = 1;  
				ENDIF
			
			)
		ENDFIX
		
		FIX("BegBalance",&BudgetYear,@RELATIVE("Total Pay Elements",0),"Budget Rate")
			"No_BL"(
            
                IF("PositionFlag"->"No_BL"->"No_PE" == 1)
				
					"No_BL" = 1;
                    "No_BL" = #Missing;
                    
				ENDIF
			
			)
		ENDFIX
		
		FIX(&BudgetYear,@RELATIVE("Total Pay Elements",0),"No_BL")
        
			"BegBalance"(
            
				IF("PositionFlag"->"No_BL"->"BegBalance"->"No_PE" == 1)
			
					"BegBalance" = "BegBalance"->{Var_CopyPositionSource};
                    
				ENDIF
			
			)
		ENDFIX
        
        FIX(&BudgetYear,@RELATIVE("Allocation Assignments",0),"No_PE")
			"BegBalance"(
				IF("PositionFlag"->"No_BL"->"BegBalance"->"No_PE" == 1)
			
					"BegBalance" = "BegBalance"->{Var_CopyPositionSource};
                    
                    
				ENDIF
			
			)
		ENDFIX
		
		FIX("BegBalance",&BudgetYear,"No_BL","No_PE")
        	"PositionFlag"(
            	IF("PositionFlag" == 1)

					"PositionFlag" = #Missing;
                    
            	ENDIF
            )
		ENDFIX
		
	ENDFIX
	
ENDFIX