//
//	File:	PrefPane.java
//

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

public class PrefPane extends JFrame {
    protected JButton okButton;
    protected JLabel prefsText;

    public PrefPane()
    {
		super();

        this.getContentPane().setLayout(new BorderLayout(10, 10));
        prefsText = new JLabel ("1 Preferences...");
        JPanel textPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 10));
        textPanel.add(prefsText);
        this.getContentPane().add (textPanel, BorderLayout.NORTH);
		
        okButton = new JButton("OK");
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 10));
        buttonPanel.add (okButton);
        okButton.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent newEvent) {
				setVisible(false);
			}	
		});
        this.getContentPane().add(buttonPanel, BorderLayout.SOUTH);
		setSize(390, 129);
		setLocation(20, 40);
    }
}