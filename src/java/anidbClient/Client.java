
import java.net.*;
import java.io.*;

public class Client {
    public static void main(String[] args) {
        try {
            String host = args[0];
            int port = Integer.parseInt(args[1]);
            int lport = Integer.parseInt(args[2]);
            String message = args[3];

            // setup local port to receive the reply
            DatagramSocket conn = new DatagramSocket(lport);
            conn.setSoTimeout(10 * 1000);

            // prepare packet for request
            InetAddress remoteAddr = InetAddress.getByName(host);
            byte outData[] = message.getBytes();
            DatagramPacket request = new DatagramPacket(outData, outData.length,
                                                        remoteAddr, port);
            conn.send(request);

            DatagramPacket reply = new DatagramPacket(new byte[2000], 2000);
            conn.receive(reply);
            byte inData[] = reply.getData();
            String answer = new String(inData, 0, reply.getLength());
            System.out.println(answer);
        } catch (java.net.UnknownHostException e) {
            System.out.println("649 Unknown host");
        } catch (java.net.SocketTimeoutException e) {
            System.out.println("399 TIMEOUT");
        } catch (java.net.SocketException e) {
            System.out.println("649 Socket error");
        } catch (java.io.IOException e) {
            System.out.println("649 IO error");
        }
        return;
    }
};
