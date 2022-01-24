import { useChannel } from '../../contexts/socketContext';
const Room = ({ roomId }) => {
  const [session, setSession] = useState(null);
  console.log(session);
  const roomChannel = useChannel(`room:${roomId}`, (session) => setSession(session));

const Room = () => {
  return <p>Hello from react</p>;
};

export default Room;
