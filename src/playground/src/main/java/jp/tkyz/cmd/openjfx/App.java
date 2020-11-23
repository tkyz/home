package jp.tkyz.cmd.openjfx;

import javafx.application.Application;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.stage.Stage;

public final class App extends Application {

	@Override
	public void start(Stage stage) throws Exception {

		Label label = new Label(getClass().getName());
		label.setAlignment(Pos.CENTER);

		Scene scene = new Scene(label, 640, 480);
		stage.setScene(scene);

		stage.show();

	}

}
