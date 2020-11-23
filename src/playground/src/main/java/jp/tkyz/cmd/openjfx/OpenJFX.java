package jp.tkyz.cmd.openjfx;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javafx.application.Application;
import jp.tkyz.core.Main;

public class OpenJFX implements Main {

	private static final Logger log = LoggerFactory.getLogger(OpenJFX.class);

	public static void main(String... args)
			throws Exception {
		Main.call(args);
	}

	@Override
	public Void call()
			throws Exception {

		Application.launch(App.class);

		return null;

	}

}
