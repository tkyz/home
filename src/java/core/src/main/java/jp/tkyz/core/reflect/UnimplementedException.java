package jp.tkyz.core.reflect;

public class UnimplementedException extends UnsupportedOperationException {

	/** シリアルバージョンUID */
	private static final long serialVersionUID = -2476820030310960801L;

	public UnimplementedException() {
	}

	public UnimplementedException(String message) {
		super(message);
	}

	public UnimplementedException(String message, Throwable cause) {
		super(message, cause);
	}

	public UnimplementedException(Throwable cause) {
		super(cause);
	}

}
