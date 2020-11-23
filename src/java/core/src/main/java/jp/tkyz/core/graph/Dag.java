package jp.tkyz.core.graph;

import java.util.List;

public interface Dag {

	public List<Class<? extends Dag>> dependencies();

}
