require "./spec_helper"

describe Liquid do
  describe Block do
    describe If do

      it "should add elsif node" do
        ifnode = If.new "if true == true"
        elsifnode = ElsIf.new "elsif true == false"
        ifnode << elsifnode
        ifnode.elsif.should_not be_nil
      end

      it "should render if true" do
        ifnode = If.new "if var"
        ifnode << Raw.new "ok"
        node_output(ifnode, Context{"var" => "exists"}).should eq "ok"
        node_output(ifnode, Context{"var" => 0}).should eq "ok"
      end

      it "should not render if false" do
        ifnode = If.new "if var"
        ifnode << Raw.new "ok"
        node_output(ifnode, Context{"var" => false}).should eq ""
        node_output(ifnode, Context.new).should eq ""
        node_output(ifnode, Context{"var" => nil}).should eq ""
      end
    end

    describe For do
      it "should be inherit BeginBlock" do
        For.new("for x in array").should be_a BeginBlock
      end

      it "should loop over array" do
        stmt = For.new "for x in myarray"
        stmt << Expression.new "x"
        ctx = Context.new
        ctx.set("myarray", ["apple", 12])
        node_output(stmt, ctx).should eq "apple12"
      end
    end

    describe Capture do
      it "should capture the content of the block" do
        block = Capture.new "capture mavar"
        block << Raw.new "Hello World!"
        ctx = Context.new
        node_output(block, ctx)
        ctx.get("mavar").should eq "Hello World!"
      end
    end

    describe Increment do
    end

    describe Assign do
      it "should assign a value" do
        expr = Assign.new "assign bool = true"
        expr2 = Assign.new "assign str = \"test\""
        expr3 = Assign.new "assign int = 12"
        ctx = Context.new

        expr.accept RenderVisitor.new ctx
        expr2.accept RenderVisitor.new ctx
        expr3.accept RenderVisitor.new ctx

        ctx.get("bool").should be_true
        ctx.get("str").should eq "test"
        ctx.get("int").should eq 12
      end
    end

    describe Filtered do
      it "should filter a string" do
        node = Filtered.new " \"whatever\" | abs"
        v = RenderVisitor.new
        node.accept v
        v.output.should eq "whatever"
      end

      it "should filter a int" do
        node = Filtered.new "-12 | abs"
        v = RenderVisitor.new
        node.accept v
        v.output.should eq "12"
      end

      it "should filter a float" do
        node = Filtered.new "-12.25 | abs"
        v = RenderVisitor.new
        node.accept v
        v.output.should eq "12.25"
      end

      it "should filter a var" do
        node = Filtered.new "var | abs"
        ctx = Context.new
        ctx.set "var", -12
        v = RenderVisitor.new ctx
        node.accept v
        v.output.should eq "12"
      end

      it "should use multiple filters" do
        node = Filtered.new "var | append: \"Hello \" | append: \"World !\""
        ctx = Context.new
        ctx.set "var", ""
        v = RenderVisitor.new ctx
        node.accept v
        v.output.should eq "Hello World !"
      end

      it "should filter with an argument" do
        node = Filtered.new "var | append: var2"
        ctx = Context.new
        ctx.set "var", "Hello"
        ctx.set "var2", " World !"
        v = RenderVisitor.new ctx
        node.accept v
        v.output.should eq "Hello World !"
      end
    end

    describe Expression do
      it "should eval true" do
        expr = Expression.new "true"
        expr.eval(Context.new).should be_true
      end

      it "should eval false" do
        expr = Expression.new "false"
        expr.eval(Context.new).should be_false
      end

      it "should eval float" do
        expr = Expression.new "12.5"
        expr2 = Expression.new "-120.5"
        expr.eval(Context.new).should eq 12.5
        expr2.eval(Context.new).should eq -120.5
      end

      it "should eval a var" do
        expr = Expression.new "myvar"
        expr2 = Expression.new "myvar.inner"
        expr3 = Expression.new "myvar.inner.inner"

        ctx = Context.new
        ctx.set("myvar", true)
        ctx.set("myvar.inner", false)
        ctx.set("myvar.inner.inner", "good")

        expr.eval(ctx).should be_true
        expr2.eval(ctx).should be_false
        expr3.eval(ctx).should eq "good"
      end

      it "should eval an comparison" do
        expr = Expression.new "true == false"
        expr2 = Expression.new "true != false"
        expr3 = Expression.new "var != 15"

        ctx = Context.new
        ctx.set "var", 16

        expr.eval(ctx).should be_false
        expr2.eval(ctx).should be_true
        expr3.eval(ctx).should be_true
      end
      # it "should eval an operation with contains keyword" do
      #   expr = Expression.new "myarr contains another"
      #   ctx = Context.new
      #   ctx.set "myarr", [12,15,13]
      #   ctx.set "another", 12
      #   expr.eval(ctx).should be_true
      # end
      it "should eval an multiple operation" do
        expr = Expression.new "test == false or some == true or another == 10"
        expr2 = Expression.new "test != false or some == false or another == 10"
        expr3 = Expression.new "test != false and some != false and another == 15"

        ctx = Context.new
        ctx.set "test", true
        ctx.set "some", true
        ctx.set "another", 15

        expr.eval(ctx).should be_true
        expr2.eval(ctx).should be_true
        expr3.eval(ctx).should be_true
      end
    end
  end
end
