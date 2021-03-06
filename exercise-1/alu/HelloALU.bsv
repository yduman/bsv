package HelloALU;
	
	typedef enum{Mul, Div, Add, Sub, And, Or, Pow} AluOps deriving (Eq, Bits);

	interface Power;
		method Action setOperands(Int#(32) a, Int#(32) b);
		method Int#(32) getResult();
	endinterface

	module mkPower(Power);
		Reg#(Int#(32)) operandA <- mkReg(0);
		Reg#(Int#(32)) operandB <- mkReg(0);
		Reg#(Int#(32)) result <- mkReg(0);
		Reg#(Bool) has_result <- mkReg(False);

		rule calculate_power (operandB > 0);
			operandB <= operandB - 1;
			result <= result * operandA;
		endrule

		rule calculate_power_done (operandB == 0 && !has_result);
			has_result <= True;
		endrule

		method Action setOperands(Int#(32) a, Int#(32) b);
			result <= 1;
			operandA <= a;
			operandB <= b;
			has_result <= False;
		endmethod

		method Int#(32) getResult() if (has_result);
			return result;
		endmethod
	endmodule

	interface HelloALU;
		method Action setupCalculation(AluOps op, Int#(32) a, Int#(32) b);
		method ActionValue#(Int#(32)) getResult();
	endinterface

	module mkHelloALU(HelloALU);
		Reg#(Int#(32)) operandA <- mkReg(0);
		Reg#(Int#(32)) operandB <- mkReg(0);
		Reg#(AluOps) operation <- mkReg(Mul);
		Reg#(Int#(32)) result <- mkReg(0);
		Reg#(Bool) has_result <- mkReg(False);
		Reg#(Bool) new_values <- mkReg(False);

		Power pow <- mkPower();

		rule calculate (new_values);
			Int#(32) tmp = 0;
			case(operation)
				Mul: tmp = operandA * operandB;
				Div: tmp = operandA / operandB;
				Add: tmp = operandA + operandB;
				Sub: tmp = operandA - operandB;
				And: tmp = operandA & operandB;
				Or: tmp = operandA | operandB;
				Pow: tmp = pow.getResult();
			endcase
			result <= tmp;
			new_values <= False;
			has_result <= True; 
		endrule

		method Action setupCalculation(AluOps op, Int#(32) a, Int#(32) b) if (!new_values);
			operandA <= a;
			operandB <= b;
			operation <= op;
			new_values <= True;
			has_result <= False;

			if (op == Pow)
				pow.setOperands(a, b);
		endmethod

		method ActionValue#(Int#(32)) getResult() if (has_result);
			has_result <= False;
			return result;
		endmethod
	endmodule

	module mkAluTestbench(Empty);
		HelloALU uut <- mkHelloALU();
		Reg#(UInt#(8)) state <- mkReg(0);

		rule testMul (state == 0);
			$display("Testing multiplication of 4 and 5...");
			uut.setupCalculation(Mul, 4, 5);
			state <= state + 1;
		endrule

		rule testDiv (state == 2);
			$display("Testing division of 4 and 2...");
			uut.setupCalculation(Div, 4, 2);
			state <= state + 1;
		endrule

		rule testAdd (state == 4);
			$display("Testing addition of 5 and 5...");
			uut.setupCalculation(Add, 5, 5);
			state <= state + 1;
		endrule

		rule testSub (state == 6);
			$display("Testing subtraction of 10 and 4...");
			uut.setupCalculation(Sub, 10, 4);
			state <= state + 1;
		endrule

		rule testAnd (state == 8);
			$display("Testing logical AND between 4 and 4...");
			uut.setupCalculation(And, 4, 4);
			state <= state + 1;
		endrule

		rule testOr (state == 10);
			$display("Testing logical OR between 8 and 8...");
			uut.setupCalculation(Or, 8, 8);
			state <= state + 1;
		endrule

		rule testPow (state == 12);
			$display("Testing 2 to the power of 5...");
			uut.setupCalculation(Pow, 2, 5);
			state <= state + 1;
		endrule

		rule endSimulation (state == 14);
			$finish();
		endrule

		rule displayResults;
			$display("Result: %d", uut.getResult());
			state <= state + 1;
		endrule

	endmodule
endpackage