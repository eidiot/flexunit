package org.flexunit.listeners
{
    import org.flexunit.reporting.FailureFormatter;
    import org.flexunit.runner.IDescription;
    import org.flexunit.runner.Result;
    import org.flexunit.runner.notification.Failure;
    import org.flexunit.runner.notification.IRunListener;

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.getTimer;

    /**
     * Text listener to show test progress and result in text.
     */
    public class TextListener extends Sprite implements IRunListener
    {
        //======================================================================
        // Constructor
        //======================================================================
        /**
         * Constructor of the listener.
         *
         * @param printProgress     If print the progress for every test.
         * @param ignoreFramework   If ignore the framework elements in the output.
         */
        public function TextListener(printProgress:Boolean = true,
                                     ignoreFramework:Boolean = true)
        {
            super();

            this.printProgress = printProgress;
            this.ignoreFramework = ignoreFramework;

            if (stage)
            {
                initialize();
            }
            else
            {
                addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
            }
        }
        //======================================================================
        // Variables
        //======================================================================
        //-- UI elements --//
        protected var resultBar:Sprite;
        protected var textDisplay:TextField;
        //-- Result display --//
        protected var resultBarHeight:Number = 10;
        protected var redColor:uint = 0xFF0000;
        protected var greenColor:uint = 0x00FF00;
        protected var resultColor:uint = 0x00FF00;
        //-- Text display --//
        protected var textMargin:Number = 5;
        //-- Flags --//
        protected var printProgress:Boolean = true;
        protected var ignoreFramework:Boolean = true;
        //-- Test variables --//
        protected var runningTest:IDescription;
        protected var lastTime:int = 0;
        //======================================================================
        // Public methods: IRunListener
        //======================================================================
        //------------------------------
        // Run started
        //------------------------------
        public function testRunStarted(description:IDescription):void
        {
            lastTime = getTimer();
        }
        //------------------------------
        // Test running
        //------------------------------
        public function testStarted(description:IDescription):void
        {
            runningTest = description;
            appendText(description.displayName + " .");
            lastTime = getTimer();
        }
        public function testFinished(description:IDescription):void
        {
            if (description == runningTest)
            {
                var time:int = getTimer() - lastTime;
                appendText(" " + time + " ms", false);
            }
        }
        public function testFailure(failure:Failure):void
        {
            resultColor = redColor;
            updateResultBar();
            if (FailureFormatter.isError(failure.exception) )
            {
                appendText(failure.description.displayName + " E");
            }
            else
            {
                appendText(failure.description.displayName + " F");
            }
        }
        public function testIgnored(description:IDescription):void
        {
            appendText(description.displayName + " I");
        }
        public function testAssumptionFailure(failure:Failure):void
        {
        }
        //------------------------------
        // Run finished
        //------------------------------
        public function testRunFinished(result:Result):void
        {
            if (result.successful)
            {
                printSuccess(result);
            }
            else
            {
                resultColor = redColor;
                printFailure(result);
            }
            updateResultBar();
        }
        //======================================================================
        // Protected methods
        //======================================================================
        //------------------------------
        // Initialization
        //------------------------------
        protected function initialize():void
        {
            initializeStage();

            createResultBar();
            createTextDisplay();

            resultColor = greenColor;
            updateResultBar();
        }
        protected function initializeStage():void
        {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.addEventListener(Event.RESIZE, stage_resizeHandler);
        }
        //------------------------------
        // Result bar
        //------------------------------
        protected function createResultBar():void
        {
            resultBar = new Sprite();
            addChild(resultBar);
        }
        protected function updateResultBar():void
        {
            if (!stage || !resultBar)
            {
                return;
            }
            with (resultBar.graphics)
            {
                clear();
                beginFill(resultColor);
                drawRect(0, 0, stage.stageWidth, resultBarHeight);
                endFill();
            }
            resultBar.y = stage.stageHeight - resultBarHeight;
        }
        //------------------------------
        // Text display
        //------------------------------
        protected function createTextDisplay():void
        {
            textDisplay = new TextField();
            addChild(textDisplay);
            textDisplay.x = textMargin;
            textDisplay.y = textMargin;
            textDisplay.defaultTextFormat = new TextFormat("Verdana", 12, 0xEEEFF0);
            resizeTextDisplay();
        }
        protected function resizeTextDisplay():void
        {
            textDisplay.width = stage.stageWidth - textMargin * 2;
            textDisplay.height = stage.stageHeight - textMargin * 2 - resultBarHeight;
        }
        protected function appendText(content:String, newLine:Boolean = true):void
        {
            if (textDisplay)
            {
                if (newLine && textDisplay.text != "")
                {
                    textDisplay.appendText("\n");
                }
                textDisplay.appendText(content);
                textDisplay.scrollV = textDisplay.maxScrollV;
            }
        }
        //------------------------------
        // Print result
        //------------------------------
        protected function printSuccess(result:Result):void
        {
            printFooter(result, "OK");
        }
        protected function printFailure(result:Result):void
        {
            if (result.failures.length == 0)
            {
                printFooter(result, "FAILURES!!!");
                return;
            }
            printLine();
            if (result.failures.length == 1)
            {
                appendText("There was 1 failure:");
            }
            else
            {
                appendText("There were " + result.failures.length + " failures:");
            }
            for each (var failure:Failure in result.failures)
            {
                printSubline();
                appendText(failure.testHeader, false);
                if (failure.stackTrace && failure.stackTrace.indexOf("at") != -1)
                {
                    var list:Array = failure.stackTrace.split("\n");
                    for each (var item:String in list)
                    {
                        if (ignoreFramework && isFramework(item))
                        {
                            continue;
                        }
                        if (item.indexOf("at") != 1 || item.indexOf("[") == -1)
                        {
                            appendText(item);
                        }
                        else
                        {
                            appendText(item.slice(0, item.indexOf("[")));
                            var lineNum:String = item.slice(item.lastIndexOf(":") + 1, -1);
                            appendText(" [" + lineNum + "]", false);
                        }
                    }
                }
            }
            printFooter(result, "FAILURES!!!");
        }
        protected function printFooter(result:Result, label:String):void
        {
            printLine();
            var msg:String = "Run: " + result.runCount + ". ";
            if (result.failureCount > 0)
            {
                msg += "Failure: " + result.failureCount + ". ";
            }
            if (result.ignoreCount > 0)
            {
                msg += "Ignore: " + result.ignoreCount + ". ";
            }
            msg += "Time: " + result.runTime + " ms.";
            appendText(msg);
            appendText(label);
        }
        protected function printLine(spaceLine:Boolean = true):void
        {
            if (spaceLine)
            {
                appendText("");
            }
            appendText("====================");
        }
        protected function printSubline(spaceLine:Boolean = true):void
        {
            if (spaceLine)
            {
                appendText("");
            }
            appendText("----------  ");
        }
        protected function isFramework(content:String):Boolean
        {
            if (content.indexOf("org.flexunit") == 4)
            {
                return true;
            }
            if (content.indexOf("flexunit.framework") == 4)
            {
                return true;
            }
            if (content.indexOf("flex.lang.reflect") == 4)
            {
                return true;
            }
            if (content.indexOf("Function/") == 4)
            {
                return true;
            }
            if (content.indexOf("global/") == 4)
            {
                return true;
            }
            if (content.indexOf("flash.utils::Timer/tick()") == 4)
            {
                return true;
            }
            if (content.indexOf("flash.events::EventDispatcher/") == 4)
            {
                return true;
            }
            return false;
        }
        //======================================================================
        // Event handlers
        //======================================================================
        protected function addedToStageHandler(event:Event):void
        {
            removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
            initialize();
        }
        protected function stage_resizeHandler(event:Event):void
        {
            resizeTextDisplay();
            updateResultBar();
        }
    }
}