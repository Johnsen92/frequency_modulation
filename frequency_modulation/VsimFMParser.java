import java.io.* ;
import java.util.regex.Pattern ;

public class VsimFMParser {
    public static void main(String[] args) {
        try{
            String currentDir = System.getProperty("user.dir") ;
            ProcessBuilder builder = new ProcessBuilder("cmd.exe", "/c", "cd X:\\DISLab\\frequency_modulation" + " && " + "vsim -c testbench_fm -do \"run -a; q\"") ;
            builder.redirectErrorStream(true) ;
            Process p = builder.start() ;
            BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream())) ;
            
            PrintWriter w = new PrintWriter("fm.log");
            
            ProcessBuilder matlabBuilder = new ProcessBuilder("cmd.exe", "/c", "X:\\Program Files\\MATLAB\\R2011a\\bin\\matlab.exe -nosplash -nodesktop -r run('FMPlotter.m')") ;
            matlabBuilder.redirectErrorStream(true) ;
            
            String timeRegex = "#\\s+Time:\\s+[0-9]+\\s+[pnum]?s\\s+Iteration:\\s+1\\s+Instance:\\s+/testbench_fm/fm" ;
            String valueRegex = "#\\s+\\*\\*\\s+Note:\\s+\\-?[0-9]\\.[0-9]*(e[\\+\\-][0-9])?.*" ;
            
            String line ;
            for(int i = 0; i < 1000; i++) {
                line = r.readLine() ;
                if(line == null) break ;
                
                if(Pattern.matches(timeRegex, line)) {
                    String[] lineSplayed = line.split("\\s+") ;
                    String time = lineSplayed[2] ;
                    
                    line = r.readLine() ;
                        
                    if(Pattern.matches(valueRegex, line)) {
                        lineSplayed = line.split("\\s+") ;
                        String value = lineSplayed[3];
                        
                        System.out.print(time) ;
                        System.out.print(" ") ;
                        System.out.println(value) ;
                        
                        w.print(time) ;
                        w.print(" ") ;
                        w.println(value) ;
                    }
                }
            }
            w.close();
            Process m = matlabBuilder.start() ;
        } catch(IOException ex) {
            ex.printStackTrace() ;
        }
    }
}